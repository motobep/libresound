import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:music_player/states/FocusState.dart';
import 'package:music_player/view/components/buttons.dart';
import 'package:provider/provider.dart';

import 'package:music_player/logger.dart';
import 'package:music_player/states/AppearanceState.dart';

class TextInput extends StatefulWidget {
  const TextInput({
    this.initial,
    this.hintText,
    this.label = '',
    this.maxWidth = double.infinity,
    this.onSave,
    this.onUnfocus,
    this.isWithCopy = false,
    super.key,
  });

  final String? initial;
  final String? hintText;
  final String label;
  final double maxWidth;
  final void Function(String s)? onSave;
  final void Function(String s)? onUnfocus;
  final bool isWithCopy;

  static TextInput fromJson(
      dynamic o, Future<void> Function(String jsArg) onChangeFunc) {
    gLogger.view('fromJson');
    return TextInput(
      initial: o['initial'],
      hintText: o['hintText'],
      label: o['label'] ?? '',
      maxWidth: o['maxWidth']?.toDouble() ?? double.infinity,
      onUnfocus: (String s) async {
        await onChangeFunc('"$s"');
        o['initial'] = s;
      },
      isWithCopy: o['isWithCopy'] ?? false,
    );
  }

  @override
  State<TextInput> createState() => _TextInputState();
}

class _TextInputState extends State<TextInput> {
  TextEditingController txtController = TextEditingController();

  String text = '';
  bool isReadOnly = true;

  final FocusNode _focusNode = FocusNode();
  late void Function() _focusListener;

  @override
  void initState() {
    final f = Provider.of<FocusManagerState>(context, listen: false);
    _focusListener = f.getInputFocusListener(_focusNode);
    _focusNode.addListener(_focusListener);

    _focusNode.addListener(_onUnfocus);

    text = widget.initial ?? '';
    txtController.text = text;
    super.initState();
  }

  void _onUnfocus() {
    if (!_focusNode.hasFocus) {
      gLogger.view('unFocus');
      widget.onUnfocus?.call(txtController.text);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onUnfocus);
    _focusNode.removeListener(_focusListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    gLogger.build('TextInput');
    final colorScheme = ColorScheme.of(context);
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != '')
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
            child: Text(widget.label),
          ),
        Row(
          children: [
            Flexible(
              child: TextField(
                focusNode: _focusNode,
                controller: txtController,
                cursorColor: Colors.grey,
                style: const TextStyle(height: 1.0),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: colorScheme.surface,
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: colorScheme.primary),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: appearanceState.lerpBgColor(0.2)),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  hintText: widget.hintText,
                  hintStyle: TextStyle(color: colorScheme.secondary),
                  constraints:
                      BoxConstraints(maxHeight: 40, maxWidth: widget.maxWidth),
                ),
                onSubmitted: (s) {
                  widget.onSave?.call(s);
                },
                onTapOutside: (_) {
                  _focusNode.unfocus();
                },
              ),
            ),
            if (widget.isWithCopy)
              IconButton(
                onPressed: () async {
                  try {
                    final contents = txtController.text;
                    await Clipboard.setData(ClipboardData(text: contents));
                  } catch (e) {
                    gLogger
                        .error('Exception copying TextInput to clipboard: $e');
                  }
                },
                icon: const Icon(Icons.copy_rounded, weight: 100),
                // icon: const Icon(PhosphorIconsLight.copySimple),
              ),
          ],
        ),
      ],
    );
  }
}

class SelectInput<T> extends StatelessWidget {
  const SelectInput({
    super.key,
    required this.elements,
    required this.initial,
    required this.onSelect,
    this.trailingIconData,
    this.trailingIconOnTap,
  });

  static SelectInput fromJson(
      dynamic o, Future<void> Function(String jsArg) onChangeFunc) {
    final List<(String, String)> els = (o['elements'] as List)
        .map((el) => (el[0] as String, el[1] as String))
        .toList();
    return SelectInput(
      elements: els,
      initial: o['initial'],
      onSelect: (s) async {
        await onChangeFunc('"$s"');
        o['initial'] = s;
      },
    );
  }

  final List<(T, String)> elements;
  final T initial;
  final void Function(T?) onSelect;
  final IconData? trailingIconData;
  final void Function(T value)? trailingIconOnTap;

  @override
  Widget build(BuildContext context) {
    final appearanceState =
        Provider.of<AppearanceState>(context, listen: false);
    return DropdownMenu<T>(
      initialSelection: initial,
      onSelected: (T? sel) {
        gLogger.blue('sel=$sel');
        onSelect(sel);
      },
      enableSearch: false,
      enableFilter: false,
      requestFocusOnTap: false,
      textStyle: const TextStyle(fontSize: 14.0),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        hoverColor: appearanceState.lerpBgColor(0.02),
        constraints: const BoxConstraints(maxHeight: 42),
        isDense: true,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1.0,
            color: appearanceState.lerpBgColor(0.20),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        ),
      ),
      alignmentOffset: const Offset(0, 3),
      menuStyle: MenuStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
        side: WidgetStateProperty.all(
          BorderSide(
            width: 1.0,
            color: appearanceState.lerpBgColor(0.20),
          ),
        ),
      ),
      dropdownMenuEntries: elements
          .map<DropdownMenuEntry<T>>(
            (el) => DropdownMenuEntry<T>(
              trailingIcon: trailingIconData != null && el.$1 != 0
                  ? IconButton(
                      icon: Icon(trailingIconData),
                      iconSize: 22,
                      color: ColorScheme.of(context).primary,
                      onPressed: () => trailingIconOnTap?.call(el.$1),
                    )
                  : null,
              value: el.$1,
              label: el.$2,
              style: el.$1 == initial
                  ? ButtonStyle(
                      padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 12)),
                      backgroundColor: WidgetStateProperty.all(
                          appearanceState.lerpBgColor(0.07)))
                  : ButtonStyle(
                      padding: WidgetStateProperty.all(
                          const EdgeInsets.symmetric(horizontal: 12)),
                    ),
            ),
          )
          .toList(),
    );
  }
}

class RadioGroupInput extends StatefulWidget {
  const RadioGroupInput({
    super.key,
    required this.elements,
    required this.initial,
    required this.onSelect,
  });

  final List<(String, String)> elements;
  final String initial;
  final void Function(String) onSelect;

  static RadioGroupInput fromJson(
      dynamic o, Future<void> Function(String jsArg) onChangeFunc) {
    final List<(String, String)> els = (o['elements'] as List)
        .map((el) => (el[0] as String, el[1] as String))
        .toList();
    return RadioGroupInput(
      elements: els,
      initial: o['initial'],
      onSelect: (s) async {
        await onChangeFunc('"$s"');
        o['initial'] = s;
      },
    );
  }

  @override
  State<RadioGroupInput> createState() => _RadioGroupInputState();
}

class _RadioGroupInputState extends State<RadioGroupInput> {
  late String _groupValue = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (var el in widget.elements)
          InkWell(
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Radio<String>(
                    value: el.$1,
                    groupValue: _groupValue,
                    onChanged: (_) {
                      widget.onSelect(el.$1);
                      setState(() {
                        _groupValue = el.$1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(el.$2),
              ],
            ),
            onTap: () {
              widget.onSelect(el.$1);
              setState(() {
                _groupValue = el.$1;
              });
            },
          ),
      ],
    );
  }
}

class CheckboxInput extends StatefulWidget {
  const CheckboxInput({
    super.key,
    this.text,
    required this.initial,
    required this.onSelect,
    this.borderColor,
    this.isToggler = false,
  });

  final String? text;
  final bool initial;
  final bool Function(bool) onSelect;
  final Color? borderColor;
  final bool isToggler;

  static CheckboxInput fromJson(
      dynamic o, Future<void> Function(bool jsArg) onToggleFunc,
      {bool isToggler = false}) {
    return CheckboxInput(
      initial: o['initial'],
      text: o['text'],
      isToggler: isToggler,
      onSelect: (bool b) {
        onToggleFunc(b);
        o['initial'] = b;
        return true;
      },
    );
  }

  @override
  State<CheckboxInput> createState() => _CheckboxInputState();
}

class _CheckboxInputState extends State<CheckboxInput> {
  late bool _isChecked = widget.initial;

  @override
  void didUpdateWidget(covariant CheckboxInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.initial != oldWidget.initial) {
      _isChecked = widget.initial;
    }
  }

  void _onChanged() {
    bool shouldUpdate = widget.onSelect.call(!_isChecked);
    if (shouldUpdate) {
      setState(() {
        _isChecked = !_isChecked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color borderClr = widget.borderColor ?? ColorScheme.of(context).onSurface;

    Widget box = !widget.isToggler
        ? SizedBox(
            width: 24,
            child: Checkbox(
              value: _isChecked,
              onChanged: (val) => _onChanged(),
              side:
                  WidgetStateBorderSide.resolveWith((Set<WidgetState> states) {
                return BorderSide(width: 1, color: borderClr);
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          )
        : SizedBox(
            height: 30,
            child: FittedBox(
              child: CupertinoSwitch(
                value: _isChecked,
                activeTrackColor: ColorScheme.of(context).primary,
                thumbColor: ColorScheme.of(context).onSurface,
                mouseCursor:
                    const WidgetStatePropertyAll(SystemMouseCursors.click),
                onChanged: (val) => _onChanged(),
              ),
            ),
          );
    if (widget.text == null) {
      return box;
    }

    return InkWell(
      onTap: _onChanged,
      child: Row(
        children: [
          box,
          const SizedBox(width: 8.0),
          Text(widget.text!),
        ],
      ),
    );
  }
}

class ButtonInput extends StatelessWidget {
  const ButtonInput({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final void Function() onTap;

  static ButtonInput fromJson(dynamic o, Future<void> Function() onTapFunc) {
    return ButtonInput(
      text: o['text'],
      onTap: () {
        onTapFunc();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StandardButton(
          text,
          onTap: onTap,
        )
      ],
    );
  }
}
