import './AtomData.dart';

class Pair {
  int length;
  String str;
  Pair(this.length, this.str);
}

class Atom {
  // padding variable is for 'moov.udta.meta', which has a historically different format
  int padding = 0;
  List<Atom> children = [];
  AtomData? data;
  Atom? parent;
  bool root = false;
  String name;

  int getHeaderLength() {
    if (name == 'root') return 0; // no header for root
    return 8 + padding;
  }

  Atom(this.name, [this.parent]) {
    if (name == 'root') root = true;
    if (name.length != 4) {
      throw Exception('Atoms must have name length of 4');
    }
  }

  Pair walk(Atom atom, int gap) {
    if (atom.data != null) {
      int atomLen = atom.data!.lengthInBytes + atom.getHeaderLength();
      return Pair(atomLen, '  ' * gap + 'Atom: ${atom.name} [$atomLen]\n');
    }

    // Otherwise we got children to parse.
    var length = atom.getHeaderLength();
    var str = '';
    for (var child in atom.children) {
      Pair pair = walk(child, gap + 1);
      str += pair.str;
      length += pair.length;
    }

    return Pair(length, '${'  ' * gap}Atom: ${atom.name} [$length]\n$str');
  }

  int getByteLength() {
    if (data != null) {
      return data!.lengthInBytes + 8;
    }

    var len = 8 + padding;
    for (var child in children) {
      len += child.getByteLength();
    }
    return len;
  }

  // Given a child path, separated by dots, return that child, or recursively create it
  Atom ensureChild(String childName) {
    List<String> pathArray = childName.split('.');
    final String firstChild = pathArray[0];

    if (!hasChild(firstChild)) addChild(firstChild);

    Atom child = getChild(firstChild);

    if (pathArray.length > 1) {
      var it = pathArray.skip(1);
      return child.ensureChild(it.join('.'));
    }
    return child;
  }

  // Get child
  int getChildIdx(String name) {
    int idx = children.indexWhere((child) => child.name == name);
    return idx;
  }

  Atom getChildByIdx(int idx) {
    assert(idx >= 0 && idx < children.length, 'Wrong child index');
    return children[idx];
  }

  Atom getChild(String name) {
    return getChildByIdx(getChildIdx(name));
  }

  bool hasChild(String name) {
    return getChildIdx(name) != -1;
  }

  // Add/insert child
  Atom addChild(String name) {
    Atom atom = Atom(name, this);
    children.add(atom);
    return atom;
  }

  Atom insertChild(int index, String name) {
    Atom atom = Atom(name, this);
    children.insert(index, atom);
    return atom;
  }
}
