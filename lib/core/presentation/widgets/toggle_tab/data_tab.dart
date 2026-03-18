part of 'toggle_tab.dart';

class DataTab {

  DataTab({
    this.title,
    this.isSelected = false,
    this.icon,
    this.counterWidget,
  });
  final String? title;
  final IconData? icon;
  final Widget? counterWidget;
  bool isSelected;
}
