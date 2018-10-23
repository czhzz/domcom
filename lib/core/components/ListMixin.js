var Nothing, addIndexes, binaryInsert, binarySearch, extendChildFamily, insertIndex, isArray, isComponent, removeIndex, setNextNodes, substractSet, toComponent;

({isArray, substractSet} = require('dc-util'));

isComponent = require('./isComponent');

toComponent = require('./toComponent');

Nothing = require('./Nothing');

// if not using binarySearch, it's too expensive to update new index after inserting or removing child
({binarySearch, binaryInsert, substractSet} = require('dc-util'));

({extendChildFamily} = require('../../dom-util'));

insertIndex = function(index, indexes) {
  var i;
  i = binarySearch(index, indexes);
  indexes.splice(i, 0, index);
  addIndexes(indexes, 1, i + 1);
};

removeIndex = function(index, indexes) {
  var i;
  i = binarySearch(index, indexes);
  if (indexes[i] === index) {
    indexes.splice(i, 1);
  }
  addIndexes(indexes, -1, i);
};

addIndexes = function(indexes, value, start) {
  var i, length;
  // value can be 1 or -1
  length = indexes.length;
  i = start;
  while (i < length) {
    indexes[i] += value;
    if (indexes[i] < 0) {
      throw 'negative index in ListMixin component';
    }
    i++;
  }
};

setNextNodes = function(children, nextNode, last, first) {
  var child, i;
  i = last;
  while (i >= first) {
    child = children[i];
    if (child.nextNode !== nextNode) {
      child.nextNode = nextNode;
      if (!child.firstNode) {
        i--;
        nextNode = child.firstNode;
      } else {
        break;
      }
    } else {
      break;
    }
  }
};

module.exports = {
  initListMixin: function() {
    var child, family, i, j, len, ref;
    this.updatingIndexes = [];
    this.attachingIndexes = [];
    this.childNodes = [];
    this.family = family = {};
    family[this.dcid] = true;
    this.children = this.children || [];
    ref = this.children;
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      child = ref[i];
      child.setHolder(this);
      child.clearRemoving();
      extendChildFamily(family, child);
    }
  },
  cloneChildrenFrom: function(component, options) {
    var child, children, i, j, len, ref;
    children = [];
    ref = component.children;
    for (i = j = 0, len = ref.length; j < len; i = ++j) {
      child = ref[i];
      children.push(this.cloneChild(child, i, options, component));
    }
    return this.setChildren(0, children);
  },
  cloneChild: function(child, index, options, srcComponent) {
    return child.clone(options);
  },
  createChildrenDom: function() {
    var child, firstNode, firstNodeIndex, index, j, len, node, ref;
    node = this.childNodes;
    firstNode = null;
    this.updatingIndexes = [];
    ref = this.children;
    for (index = j = 0, len = ref.length; j < len; index = ++j) {
      child = ref[index];
      child.setHolder(this);
      child.renderDom(child.baseComponent);
      node.push(child.node);
      if (!firstNode && child.firstNode) {
        firstNode = child.firstNode;
        firstNodeIndex = index;
      }
    }
    this.childrenFirstNode = firstNode;
    this.firstNodeIndex = firstNodeIndex;
  },
  updateChildrenDom: function() {
    var child, children, index, j, len, node, updatingIndexes;
    updatingIndexes = this.updatingIndexes;
    this.updatingIndexes = [];
    node = this.childNodes;
    children = this.children;
    for (j = 0, len = updatingIndexes.length; j < len; j++) {
      index = updatingIndexes[j];
      child = children[index];
      child.setHolder(this);
      child.renderDom(child.baseComponent);
      index = children.indexOf(child);
      node[index] = child.node;
      this.updateChildrenFirstNode(child, index);
    }
  },
  insertChildBefore: function(child, refChild) {
    return this.insertChild(refChild, child);
  },
  insertChildAfter: function(child, refChild) {
    var children;
    ({children} = this);
    if (isComponent(refChild)) {
      refChild = children.indexOf(refChild);
      if (refChild < 0) {
        refChild = 0;
      }
    }
    return this.insertChild(refChild + 1, child);
  },
  pushChild: function(...children) {
    var i, length, thisChildren;
    thisChildren = this.children;
    length = children.length;
    i = 0;
    while (i < length) {
      this.insertChild(thisChildren.length, children[i]);
      i++;
    }
    return this;
  },
  insertChild: function(refChild, child) {
    var children, index, length;
    children = this.children;
    length = children.length;
    if (refChild == null) {
      index = length;
    } else if (isComponent(refChild)) {
      index = children.indexOf(refChild);
      if (index < 0) {
        index = length;
      }
    } else if (refChild > length) {
      index = length;
      refChild = null;
    } else if (refChild < 0) {
      index = 0;
      refChild = null;
    } else {
      index = refChild;
      refChild = children[index];
    }
    this.emit('onInsertChild', index, refChild, child);
    child = toComponent(child);
    return this._insertChild(index, child);
  },
  _insertChild: function(index, child) {
    var children;
    children = this.children;
    children.splice(index, 0, child);
    child.setHolder(this);
    child.clearRemoving();
    child.parentNode = this.childParentNode;
    if (index === children.length - 1) {
      child.setNextNode(this.childrenNextNode);
    } else {
      child.setNextNode(children[index + 1].firstNode || children[index + 1].nextNode);
    }
    if (this.node) {
      this.childNodes.splice(index, 0, child.node);
      if (!child.node || !child.valid) {
        this.valid = false;
        insertIndex(index, this.updatingIndexes);
        if (this.holder) {
          this.holder.invalidateContent(this);
        }
      }
      if (this.holder) {
        this.holder.invalidateAttach(this);
      }
      this.attachValid = false;
      insertIndex(index, this.attachingIndexes);
      if (child.firstNode && (!this.childrenFirstNode || index <= this.firstNodeIndex)) {
        this.childrenFirstNode = child.firstNode;
        this.firstNodeIndex = index;
      }
    }
    return this;
  },
  unshiftChild: function(...children) {
    var i;
    i = children.length - 1;
    while (i >= 0) {
      this.insertChild(0, children[i]);
      i--;
    }
    return this;
  },
  shiftChild: function() {
    return this.removeChild(0);
  },
  popChild: function() {
    var length;
    length = this.children.length;
    if (length) {
      return this.removeChild(length - 1);
    } else {
      return this;
    }
  },
  removeChild: function(child) {
    var childFirstNode, children, index;
    if (child == null) {
      dc.error('child to be removed is undefined');
    }
    children = this.children;
    if (isComponent(child)) {
      index = children.indexOf(child);
      if (index < 0) {
        dc.error('child to be removed is not in the children');
      }
    } else if (child >= children.length || child < 0) {
      dc.error('child(' + child + ') to be removed is out of range');
    } else {
      index = child;
      child = children[index];
    }
    removeIndex(index, this.updatingIndexes);
    child = children[index];
    if (this.node) {
      this.childNodes.splice(index, 1);
      if (childFirstNode = child.firstNode) {
        if (this.firstNodeIndex === index) {
          this.setFirstNodeWithFollowing(index);
        }
        this.linkNextNode(index, childFirstNode, child.nextNode);
      }
      child.markRemovingDom();
      removeIndex(index, this.attachingIndexes);
    }
    substractSet(this.family, child.family);
    children.splice(index, 1);
    if (child.holder === this) {
      child.holder = null;
    }
    return child;
  },
  removeRange: function(start, stop) {
    var children, index, last;
    children = this.children;
    last = children.length - 1;
    index = start;
    if (index < 0) {
      index = 0;
    }
    if (stop > last) {
      stop = last;
    }
    while (index <= stop) {
      this.removeChild(index);
      index++;
    }
    return this;
  },
  setFirstNodeWithFollowing: function(index) {
    var children, firstNode, length;
    children = this.children;
    length = children.length;
    index++;
    while (index < length) {
      if (firstNode = children[index].firstNode) {
        this.childrenFirstNode = firstNode;
        this.firstNodeIndex = index;
        return;
      }
      index++;
    }
    this.childrenFirstNode = null;
  },
  replaceChild: function(oldChild, newChild) {
    var children, index;
    children = this.children;
    if (isComponent(oldChild)) {
      index = children.indexOf(oldChild);
      if (index < 0) {
        dc.error('oldChild to be replaced is not in the children');
      }
    } else {
      if (oldChild >= children.length || oldChild < 0) {
        dc.error('oldChild(' + oldChild + ') to be replaced is out of range');
      }
      index = oldChild;
      oldChild = children[index];
    }
    this.emit('onReplaceChild', index, oldChild, newChild);
    newChild = toComponent(newChild);
    return this._replaceChild(index, oldChild, newChild);
  },
  _replaceChild: function(index, oldChild, newChild) {
    var children;
    children = this.children;
    if (oldChild === newChild) {
      return this;
    }
    children[index] = newChild;
    if (oldChild.holder === this) {
      oldChild.holder = null;
    }
    oldChild.markRemovingDom();
    newChild.setHolder(this);
    newChild.clearRemoving();
    newChild.parentNode = oldChild.parentNode;
    newChild.nextNode = oldChild.nextNode;
    substractSet(this.family, oldChild.family);
    extendChildFamily(this.family, newChild);
    if (this.node) {
      this.childNodes[index] = newChild.node;
      if (!newChild.node || !newChild.valid) {
        this.invalidateContent(newChild);
      }
      this.invalidateAttach(newChild);
      dc.removingChildren[oldChild.dcid] = oldChild;
      this.updateChildrenFirstNode(newChild, index);
    }
    return this;
  },
  updateChildrenFirstNode: function(newChild, index) {
    if (this.childrenFirstNode) {
      if (newChild.firstNode) {
        if (index <= this.firstNodeIndex) {
          this.childrenFirstNode = newChild.firstNode;
          this.firstNodeIndex = index;
        }
      } else if (index === this.firstNodeIndex) {
        this.setFirstNodeWithFollowing(index);
      }
    } else {
      if (newChild.firstNode) {
        this.childrenFirstNode = newChild.firstNode;
        this.firstNodeIndex = index;
      }
    }
  },
  setChildren: function(startIndex, newChildren) {
    var child, children, i, j, len, n, oldChildrenLength;
    children = this.children;
    oldChildrenLength = children.length;
    n = oldChildrenLength;
    while (n < startIndex) {
      this.pushChild(new Nothing());
      n++;
    }
    for (i = j = 0, len = newChildren.length; j < len; i = ++j) {
      child = newChildren[i];
      if (startIndex + i < oldChildrenLength) {
        this.replaceChild(startIndex + i, newChildren[i]);
      } else {
        this.pushChild(newChildren[i]);
      }
    }
    return this;
  },
  setLength: function(newLength) {
    var children, last;
    children = this.children;
    if (newLength >= children.length) {
      return this;
    } else {
      last = children.length - 1;
      while (last >= newLength) {
        this.removeChild(last);
        last--;
      }
      return this;
    }
  },
  invalidateContent: function(child) {
    var index;
    index = this.children.indexOf(child);
    binaryInsert(index, this.updatingIndexes);
    if (this.valid) {
      this.valid = false;
      this.holder && this.holder.invalidateContent(this);
    }
    return this;
  },
  invalidateChildren: function() {
    var child, j, len, ref;
    this.invalidate();
    ref = this.children;
    for (j = 0, len = ref.length; j < len; j++) {
      child = ref[j];
      child.valid = false;
    }
    return this;
  },
  attachChildren: function() {
    var childParentNode;
    childParentNode = this.childParentNode;
    if (!childParentNode || !this.attachValid || !this.childNodes.parentNode) {
      this.attachValid = true;
      if (this.isList) {
        this.childParentNode = this.parentNode;
        this.childrenNextNode = this.nextNode;
      } else if (!childParentNode) {
        this.childParentNode = this.node;
        this.childrenNextNode = null;
      }
      if (this.childParentNode !== this.childNodes.parentNode) {
        this.attachAllChildren();
      } else {
        this.attachInvalidChildren();
      }
    }
  },
  attachAllChildren: function() {
    var child, children, i, length, nextNode, parentNode;
    parentNode = this.childParentNode;
    children = this.children;
    if (length = children.length) {
      nextNode = this.childrenNextNode;
      i = length - 1;
      while (child = children[i]) {
        child.setHolder(this);
        child.parentNode = parentNode;
        child.setNextNode(nextNode);
        child.attachParent();
        nextNode = child.firstNode || nextNode;
        i--;
      }
      child = children[0];
      this.childNodes.parentNode = parentNode;
    }
  },
  attachInvalidChildren: function() {
    var attachingIndexes, child, children, i, listIndex, nextNode, parentNode, prevIndex;
    attachingIndexes = this.attachingIndexes;
    if (attachingIndexes.length) {
      this.attachingIndexes = [];
      if (parentNode = this.childParentNode) {
        nextNode = this.childrenNextNode;
        children = this.children;
        i = attachingIndexes.length - 1;
        prevIndex = children.length - 1;
        while (i >= 0) {
          listIndex = attachingIndexes[i];
          setNextNodes(children, nextNode, prevIndex, listIndex);
          child = children[listIndex];
          child.setHolder(this);
          child.parentNode = parentNode;
          child.attachParent();
          nextNode = child.firstNode || child.nextNode;
          prevIndex = listIndex - 1;
          i--;
        }
        setNextNodes(children, nextNode, prevIndex, 0);
        this.childNodes.parentNode = parentNode;
      }
    }
  },
  propagateChildNextNode: function(child, nextNode) {
    var children, index;
    children = this.children;
    if (isComponent(child)) {
      index = children.indexOf(child) - 1;
    } else {
      index = child - 1;
    }
    while (child = children[index]) {
      child.setNextNode(nextNode);
      if (child.firstNode) {
        return;
      }
      index--;
    }
    if (!this.isTag && this.holder) {
      this.holder.propagateChildNextNode(this, nextNode);
    }
  },
  linkNextNode: function(child, oldNode, nextNode) {
    var children, index;
    children = this.children;
    if (isComponent(child)) {
      index = children.indexOf(child) - 1;
    } else {
      index = child - 1;
    }
    while (index >= 0) {
      child = children[index];
      if (child.nextNode === oldNode) {
        child.setNextNode(nextNode);
      } else {
        return;
      }
      index--;
    }
    if (!this.isTag && this.holder) {
      this.holder.linkNextNode(this, oldNode, nextNode);
    }
  }
};
