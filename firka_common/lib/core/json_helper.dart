List<T> listToTyped<T>(List<dynamic> dynamicList) {
  var newList = List<T>.empty(growable: true);

  for (var item in dynamicList) {
    newList.add(item as T);
  }

  return newList;
}
