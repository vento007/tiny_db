enum UpdateOpType {
  set,
  delete,
  increment,
  decrement,
  push,
  pull,
  pop,
  addUnique,
}

class UpdateAction {
  final UpdateOpType type;
  final List<String> pathSegments;
  final dynamic value;

  UpdateAction(this.type, this.pathSegments, [this.value]);

  @override
  String toString() =>
      'UpdateAction(type: $type, path: $pathSegments, value: $value)';
}

class UpdateOperations {
  final List<UpdateAction> _actions = [];

  UpdateOperations();

  List<UpdateAction> get actions => List.unmodifiable(_actions);

  UpdateOperations push(String fieldPath, dynamic value) {
    if (fieldPath.isEmpty) {
      throw ArgumentError('Field path cannot be empty for push operation.');
    }
    _actions.add(UpdateAction(UpdateOpType.push, fieldPath.split('.'), value));
    return this;
  }

  UpdateOperations pull(String fieldPath, dynamic valueToRemove) {
    if (fieldPath.isEmpty) {
      throw ArgumentError('Field path cannot be empty for pull operation.');
    }
    _actions.add(
      UpdateAction(UpdateOpType.pull, fieldPath.split('.'), valueToRemove),
    );
    return this;
  }

  UpdateOperations set(String fieldPath, dynamic value) {
    if (fieldPath.isEmpty) {
      throw ArgumentError('Field path cannot be empty for set operation.');
    }
    _actions.add(UpdateAction(UpdateOpType.set, fieldPath.split('.'), value));
    return this;
  }

  UpdateOperations delete(String fieldPath) {
    if (fieldPath.isEmpty) {
      throw ArgumentError('Field path cannot be empty for delete operation.');
    }
    _actions.add(UpdateAction(UpdateOpType.delete, fieldPath.split('.')));
    return this;
  }

  UpdateOperations increment(String fieldPath, num amount) {
    if (fieldPath.isEmpty) {
      throw ArgumentError(
        'Field path cannot be empty for increment operation.',
      );
    }
    _actions.add(
      UpdateAction(UpdateOpType.increment, fieldPath.split('.'), amount),
    );
    return this;
  }

  UpdateOperations decrement(String fieldPath, num amount) {
    if (fieldPath.isEmpty) {
      throw ArgumentError(
        'Field path cannot be empty for decrement operation.',
      );
    }
    _actions.add(
      UpdateAction(UpdateOpType.decrement, fieldPath.split('.'), amount),
    );
    return this;
  }

  UpdateOperations pop(String fieldPath) {
    if (fieldPath.isEmpty) {
      throw ArgumentError('Field path cannot be empty for pop operation.');
    }

    _actions.add(UpdateAction(UpdateOpType.pop, fieldPath.split('.')));
    return this;
  }

  UpdateOperations addUnique(String fieldPath, dynamic value) {
    if (fieldPath.isEmpty) {
      throw ArgumentError(
        'Field path cannot be empty for addUnique operation.',
      );
    }
    _actions.add(
      UpdateAction(UpdateOpType.addUnique, fieldPath.split('.'), value),
    );
    return this;
  }
}
