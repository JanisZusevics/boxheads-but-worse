@tool
class_name BrsNode
extends Object

# Match your enum from C#
const SEARCH_DIRECT := 0
const SEARCH_RECURSIVE := 1
const SEARCH_DIRECT_WITH_NODE_CHILDREN := 2
const SEARCH_RECURSIVE_NODE_CHILDREN_ONLY := 3


# -------------------------------------------------------------------
# FindParentOfType<T>
# -------------------------------------------------------------------
static func find_parent_of_type(start_node: Node, type_name: String) -> Node:
	var current := start_node
	while current:
		#if current.get_class() == type_name or current is ClassDB.get_class(type_name):
		if current.get_class() == type_name:
			return current
		current = current.get_parent()
	return null


# -------------------------------------------------------------------
# GetRelativeNodePath_StringCompare
# -------------------------------------------------------------------
static func get_relative_node_path_string_compare(node_a: Node, node_b: Node) -> String:
	if node_a == null or node_b == null:
		push_error("One or both nodes are null. Unable to get path.")
		return ""

	var path_a := str(node_a.get_path())
	var path_b := str(node_b.get_path())

	var a_parts := path_a.split("/")
	var b_parts := path_b.split("/")

	var common := 0
	while (
		common < a_parts.size()
		and common < b_parts.size()
		and a_parts[common] == b_parts[common]
	):
		common += 1

	var result := []

	# Up from A
	for i in range(common, a_parts.size()):
		result.append("..")

	# Then descend into B
	for i in range(common, b_parts.size()):
		result.append(b_parts[i])

	return "/".join(result)


# -------------------------------------------------------------------
# GetNodeAPathToB
# -------------------------------------------------------------------
static func get_node_a_path_to_b(node_a: Node, node_b: Node) -> String:
	if node_a and node_b:
		return str(node_a.get_path_to(node_b))
	push_error("One or both nodes are null. Unable to get path.")
	return ""


# -------------------------------------------------------------------
# GetChildOfType<T>
# -------------------------------------------------------------------
static func get_child_of_type(parent: Node, type_name: String, search_mode: int) -> Node:
	if parent == null:
		push_error("(BrsNode.get_child_of_type) parent is null.")
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
				var found = BrsNode.get_child_of_type(child, type_name, SEARCH_RECURSIVE)
				if found:
					return found

		SEARCH_DIRECT_WITH_NODE_CHILDREN:
			# Check direct children first
			for child in parent.get_children():
				#if child.get_class() == type_name or child is ClassDB.get_class(type_name):
				if child.get_class() == type_name:
					return child

			# Then check children of plain Node/Node2D/Node3D
			for child in parent.get_children():
				var c := child.get_class()
				if c == "Node" or c == "Node2D" or c == "Node3D":
					for sub in child.get_children():
						#if sub.get_class() == type_name or sub is ClassDB.get_class(type_name):
						if sub.get_class() == type_name:
							return sub

		SEARCH_RECURSIVE_NODE_CHILDREN_ONLY:
			for d in BrsNode.get_all_descendants(parent):
				#if d.get_class() == type_name or d is ClassDB.get_class(type_name):
				if d.get_class() == type_name:
					return d

	return null


# -------------------------------------------------------------------
# GetChildrenOfType<T>
# -------------------------------------------------------------------
static func get_children_of_type(parent: Node, type_name: String, search_mode: int) -> Array:
	var result: Array = []

	if parent == null:
		push_error("[BrsNode.get_children_of_type] parent is null.")
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
				result += BrsNode.get_children_of_type(child, type_name, SEARCH_RECURSIVE)

		SEARCH_DIRECT_WITH_NODE_CHILDREN:
			# Direct children
			for child in parent.get_children():
				#if child.get_class() == type_name or child is ClassDB.get_class(type_name):
				if child.get_class() == type_name:
					result.append(child)

			# Children of Node/Node2D/Node3D
			for child in parent.get_children():
				var c := child.get_class()
				if c == "Node" or c == "Node2D" or c == "Node3D":
					for sub in child.get_children():
						#if sub.get_class() == type_name or sub is ClassDB.get_class(type_name):
						if sub.get_class() == type_name:
							result.append(sub)

		SEARCH_RECURSIVE_NODE_CHILDREN_ONLY:
			for d in BrsNode.get_all_descendants(parent):
				#if d.get_class() == type_name or d is ClassDB.get_class(type_name):
				if d.get_class() == type_name:
					result.append(d)

	return result


# -------------------------------------------------------------------
# GetChildrenOfType_Array<T>
# -------------------------------------------------------------------
static func get_children_of_type_array(parent: Node, type_name: String, search_mode: int) -> Array:
	return BrsNode.get_children_of_type(parent, type_name, search_mode)


# -------------------------------------------------------------------
# GetAllDescendants (enumerable version)
# -------------------------------------------------------------------
static func get_all_descendants(start_node: Node) -> Array:
	if start_node == null:
		push_error("(BrsNode.get_all_descendants) start_node is null.")
		return []

	var out: Array = []
	var queue: Array = start_node.get_children()

	while queue.size() > 0:
		var cur: Node = queue.pop_front()
		out.append(cur)

		for c in cur.get_children():
			queue.append(c)

	return out


# -------------------------------------------------------------------
# GetAllDescendants_List
# -------------------------------------------------------------------
static func get_all_descendants_list(start_node: Node) -> Array:
	var result: Array = []

	if start_node == null:
		push_error("BrsNode.get_all_descendants_list: startNode is null.")
		return result

	var process := start_node.get_children()

	var i := 0
	while i < process.size():
		var cur: Node = process[i]
		result.append(cur)

		for c in cur.get_children():
			process.append(c)

		i += 1

	return result
