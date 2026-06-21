part of '../benefit_map.dart';

class _MapSearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  const _MapSearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<_MapSearchField> createState() => _MapSearchFieldState();
}

class _MapSearchFieldState extends State<_MapSearchField> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final has = widget.controller.text.isNotEmpty;
    if (has != _hasText) {
      setState(() => _hasText = has);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 18, right: 10),
            child: Icon(Icons.search, color: AppColors.primaryAccent, size: 30),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSubmitted,
              decoration: const InputDecoration(
                hintText: '매장명으로 검색',
                hintStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSub,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 19),
              ),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textMain,
              ),
            ),
          ),
          if (_hasText) ...[
            GestureDetector(
              onTap: widget.onClear,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.cancel, color: AppColors.textSub, size: 22),
              ),
            ),
            GestureDetector(
              onTap: widget.onSearch,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryAccent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  '검색',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
