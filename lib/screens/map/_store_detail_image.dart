part of 'store_detail_screen.dart';

void _openImageViewer(
  BuildContext context,
  List<_StoreImageItem> images,
  int initialIndex,
) {
  if (images.isEmpty) return;

  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.92),
    builder: (_) {
      final controller = PageController(initialPage: initialIndex);

      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    panEnabled: false,
                    scaleEnabled: true,
                    child: images[index].buildImage(BoxFit.contain),
                  ),
                );
              },
            ),
            Positioned(
              top: 44,
              right: 18,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _StoreImageItem {
  final String value;
  final _StoreImageType type;

  const _StoreImageItem._(this.value, this.type);

  factory _StoreImageItem.asset(String value) {
    return _StoreImageItem._(value, _StoreImageType.asset);
  }

  factory _StoreImageItem.network(String value) {
    return _StoreImageItem._(value, _StoreImageType.network);
  }

  factory _StoreImageItem.file(String value) {
    return _StoreImageItem._(value, _StoreImageType.file);
  }

  Widget buildImage(BoxFit fit) {
    switch (type) {
      case _StoreImageType.asset:
        return Image.asset(
          value,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallbackBox(),
        );
      case _StoreImageType.network:
        return Image.network(
          value,
          fit: fit,
          errorBuilder: (_, __, ___) => _fallbackBox(),
        );
      case _StoreImageType.file:
        return Image.file(
          File(value),
          fit: fit,
          errorBuilder: (_, __, ___) => _fallbackBox(),
        );
    }
  }

  Widget _fallbackBox() {
    return Container(
      color: AppColors.surfaceSoft,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textSub,
      ),
    );
  }
}

enum _StoreImageType { asset, network, file }
