'''
Godot has no static classes in GDScript, so the correct equivalent is a script you autoload or a class_name you access statically:

# Put this in res://addons/BrsSSS/BrsEditor.gd
class_name BrsEditor
@tool


Then you can call:

BrsEditor.get_selected_node()
BrsEditor.get_children_of_type_editor(node, "Button", BrsEditor.SEARCH
'''


@tool
class_name BrsEditor
extends Object

# -------------------------------------------------------------------
# ENUM REPLACEMENT FOR SearchModeEnum
# -------------------------------------------------------------------
const SEARCH_DIRECT := 0
const SEARCH_RECURSIVE := 1
const SEARCH_DIRECT_WITH_NODE_CHILDREN := 2
const SEARCH_RECURSIVE_NODE_CHILDREN_ONLY := 3

# -------------------------------------------------------------------
# Utility: get all descendants (breadth-first)
# -------------------------------------------------------------------
static func _all_descendants_bfs(root: Node) -> Array:
	if root == null:
		push_error("(GetAllDescendants_Editor) startNode is null.")
		return []

	var queue: Array = root.get_children()
	var out: Array = []

	while queue.size() > 0:
		var cur: Node = queue.pop_front()
		out.append(cur)
		for c in cur.get_children():
			queue.append(c)

	return out


# -------------------------------------------------------------------
# GetChildOfType_Editor<T>
# -------------------------------------------------------------------
static func get_child_of_type_editor(parent: Node, type_name: String, search_mode: int) -> Node:
	if parent == null:
		push_error("(GetChildOfType_Editor) parent is null")
		return null

	match search_mode:
		SEARCH_DIRECT:
			for child in parent.get_children():
				#if child.get_class() == type_name or child is ClassDB.get_class(type_name):
				if child.get_class() == type_name:
					return child

		SEARCH_RECURSIVE:
			for child in parent.get_children():
				#if child.get_class() == type_name or child is ClassDB.get_class(type_name):
				if child.get_class() == type_name:
					return child
				var found = BrsEditor.get_child_of_type_editor(child, type_name, SEARCH_RECURSIVE)
				if found:
					return found

		SEARCH_DIRECT_WITH_NODE_CHILDREN:
			for child in parent.get_children():
				#if child.get_class() == type_name or child is ClassDB.get_class(type_name):
				if child.get_class() == type_name:
					return child
			for child in parent.get_children():
				if child.get_class() == "Node":
					for gc in child.get_children():
						#if gc.get_class() == type_name or gc is ClassDB.get_class(type_name):
						if gc.get_class() == type_name:
							return gc

		SEARCH_RECURSIVE_NODE_CHILDREN_ONLY:
			for d in _all_descendants_bfs(parent):
				#if d.get_class() == type_name or d is ClassDB.get_class(type_name):
				if d.get_class() == type_name:
					return d

	return null


# -------------------------------------------------------------------
# GetChildrenOfType_Editor<T> (List<T>)
# -------------------------------------------------------------------
static func get_children_of_type_editor(parent: Node, type_name: String, search_mode: int) -> Array:
	var result: Array = []

	if parent == null:
		push_error("(GetChildrenOfType_Editor) parent is null")
		return result

	match search_mode:
		SEARCH_DIRECT:
			for child in parent.get_children():
				
				#if child.get_class() == type_name or child is ClassDB.get_class(type_name):
				if child.get_class() == type_name:
					result.append(child)

		SEARCH_RECURSIVE:
			for child in parent.get_children():
				#if child.get_class() == type_name or child is ClassDB.get_class(type_name):
				if child.get_class() == type_name:
					result.append(child)
				result += BrsEditor.get_children_of_type_editor(child, type_name, SEARCH_RECURSIVE)

		SEARCH_DIRECT_WITH_NODE_CHILDREN:
			for child in parent.get_children():
				#if child.get_class() == type_name or child is ClassDB.get_class(type_name):
				if child.get_class() == type_name:
					result.append(child)

			for child in parent.get_children():
				if child.get_class() == "Node":
					for gc in child.get_children():
						#if gc.get_class() == type_name or gc is ClassDB.get_class(type_name):
						if gc.get_class() == type_name:
							result.append(gc)

		SEARCH_RECURSIVE_NODE_CHILDREN_ONLY:
			for n in _all_descendants_bfs(parent):
				#if n.get_class() == type_name or n is ClassDB.get_class(type_name):
				if n.get_class() == type_name:
					result.append(n)

	return result


# -------------------------------------------------------------------
# GetChildrenOfType_Array_Editor<T>
# -------------------------------------------------------------------
static func get_children_of_type_array_editor(parent: Node, type_name: String, search_mode: int) -> Array:
	return BrsEditor.get_children_of_type_editor(parent, type_name, search_mode)


# -------------------------------------------------------------------
# GetPath_Editor()
# -------------------------------------------------------------------
static func get_path_editor(node: Node) -> String:
	if node == null:
		return ""

	if node.owner:
		var owner: Node = node.owner
		var rel: NodePath = owner.get_path_to(node)
		return "%s/%s" % [owner.name, rel]
	else:
		return str(node.get_path())


# -------------------------------------------------------------------
# FixEditorPath_Truncate (regex based)
# -------------------------------------------------------------------
static func fix_editor_path_truncate(long_path: String) -> String:
	var rev := long_path.reverse()

	var re := RegEx.new()
	re.compile("/(\\d{4}@)")

	var matches := re.search_all(rev)
	if matches.is_empty():
		return "No matches found in reversed node path."

	var modified_rev := re.sub(rev, "", true)
	return modified_rev.reverse()


# -------------------------------------------------------------------
# DetectAndMakeNodesUnique()
# -------------------------------------------------------------------
static func detect_and_make_nodes_unique(template: String, editor_plugin: EditorPlugin = null) -> void:
	var re := RegEx.new()
	re.compile("\\b(get_node|GetNode)\\(\"([^\"]+)\"\\)")

	var matches := re.search_all(template)

	for m in matches:
		var func_name := m.get_string(1)
		var extracted_path := m.get_string(2)

		var found_node := BrsEditor.get_selected_node()
		if found_node == null:
			push_error("Node '%s' not found – skipping uniqueness." % extracted_path)
			continue

		if found_node.is_unique_name_in_owner():
			print("Node already unique; skipping: ", found_node)
			continue

		print("Making node unique triggered by ", func_name, " for ", extracted_path)
		BrsEditor.make_node_unique(found_node, editor_plugin)


# -------------------------------------------------------------------
# MakeNodeUnique()
# -------------------------------------------------------------------
static func make_node_unique(node: Node = null, editor_plugin: EditorPlugin = null) -> void:
	var node_to_edit := node if node else BrsEditor.get_selected_node()
	if node_to_edit == null:
		push_error("No node selected!")
		return

	var scene_root := EditorInterface.get_edited_scene_root()
	
	if scene_root == null:
		push_error("No open scene found!")
		return

	if node_to_edit.owner == null:
		node_to_edit.owner = scene_root

	if editor_plugin:
		var undo := editor_plugin.get_undo_redo()
		undo.create_action("Set Node Unique")
		undo.add_do_property(node_to_edit, "unique_name_in_owner", true)
		undo.add_undo_property(node_to_edit, "unique_name_in_owner", node_to_edit.is_unique_name_in_owner())
		undo.commit_action()

	node_to_edit.set_unique_name_in_owner(true)
	EditorInterface.get_resource_filesystem().scan()

	print("Node %s set to Unique." % node_to_edit.name)


# -------------------------------------------------------------------
# GetSelectedNodePath()
# -------------------------------------------------------------------
static func get_selected_node_path() -> String:
	var sel := EditorInterface.get_selection().get_selected_nodes()
	if sel.is_empty():
		print("Select a node first!")
		return ""
	var root := EditorInterface.get_edited_scene_root()
	return str(root.get_path_to(sel[0]))


# -------------------------------------------------------------------
# GetSelectedNode()
# -------------------------------------------------------------------
static func get_selected_node() -> Node:
	var sel := EditorInterface.get_selection().get_selected_nodes()
	if sel.is_empty():
		print("Select a node first!")
		return null
	return sel[0]


# -------------------------------------------------------------------
# GetSelectedNodes()
# -------------------------------------------------------------------
static func get_selected_nodes() -> Array:
	var sel := EditorInterface.get_selection().get_selected_nodes()
	if sel.is_empty():
		print("Select a node first!")
		return []
	return sel.duplicate()


# -------------------------------------------------------------------
# GetCurrentSceneAbsoluteFilePath()
# -------------------------------------------------------------------
static func get_current_scene_absolute_file_path(node: Node) -> String:
	var scene_file := node.get_tree().edited_scene_root.scene_file_path
	return ProjectSettings.globalize_path(scene_file)


# -------------------------------------------------------------------
# GetSelectedNodeName()
# -------------------------------------------------------------------
static func get_selected_node_name() -> String:
	var sel := EditorInterface.get_selection().get_selected_nodes()
	if sel.is_empty():
		return ""
	return sel[0].name


# -------------------------------------------------------------------
# RefreshEditorNodeTree()
# -------------------------------------------------------------------
static func refresh_editor_node_tree():
	var iface := EditorInterface
	var root := iface.get_edited_scene_root()
	if root == null:
		push_error("No edited scene root.")
		return

	iface.get_resource_filesystem().scan()
	iface.inspect_object(root)


# -------------------------------------------------------------------
# GetAllNodesInCurrentScene()
# -------------------------------------------------------------------
static func get_all_nodes_in_current_scene() -> Array:
	var scene_root := BrsEditor.get_root_node_from_scene_tree()
	if scene_root == null:
		return []

	var nodes: Array = []
	for child in scene_root.get_children():
		nodes.append(child)
		nodes += BrsNode.get_all_descendants_list(child)
	return nodes


# -------------------------------------------------------------------
# GetRootNodeFromSceneTree()
# -------------------------------------------------------------------
static func get_root_node_from_scene_tree() -> Node:
	return EditorInterface.get_edited_scene_root()


# -------------------------------------------------------------------
# TruncateEditorPath()
# -------------------------------------------------------------------
static func truncate_editor_path(full_path: String, scene_name: String) -> String:
	var idx := full_path.rfind(scene_name)
	if idx >= 0:
		var slash := full_path.rfind("/", idx)
		if slash >= 0:
			return full_path.substr(slash + 1)
	return full_path
