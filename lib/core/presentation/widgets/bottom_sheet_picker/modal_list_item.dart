abstract class ModalListItem<T> {
  ModalListItem({
    required this.title,
    this.isLocked,
    required this.value,
  });
  String title;
  bool? isLocked;
  T value;
}

class CustomModalListItem<T> extends ModalListItem<T> {
  CustomModalListItem(
      {required super.title, required super.value, super.isLocked,});
}
