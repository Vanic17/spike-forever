extends RefCounted
## Immutable subtree indices shared by rigs with the same hierarchy.
## Build once, instead of searching 145 ancestor chains for each IK rotation.
static var cache: Dictionary = {}
static func descendants(parents: Array[int]) -> Array:
	var key := hash(parents)
	if cache.has(key): return cache[key]
	var result: Array = []
	for i in parents.size(): result.append(PackedInt32Array())
	for bone in parents.size():
		var ancestor := bone
		while ancestor >= 0 and ancestor < parents.size():
			result[ancestor].append(bone)
			var next: int = parents[ancestor]
			if next >= ancestor: break
			ancestor = next
	cache[key] = result
	return result
