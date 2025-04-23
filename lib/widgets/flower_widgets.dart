// lib/widgets/flower_widgets.dart
import 'package:flutter/material.dart';
import 'package:my_tflit_app/models/flower.dart';

class FlowerCard extends StatelessWidget {
  final Flower flower;
  final VoidCallback? onTap;

  const FlowerCard({
    Key? key,
    required this.flower,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 6, left: 6),
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 75,
                width: double.infinity,
                child: Image.asset(
                  flower.image,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flower.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      flower.latinName,
                      style: const TextStyle(
                        fontSize: 9,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      flower.description,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlowerGallery extends StatefulWidget {
  final List<Flower> flowers;
  final Function(Flower)? onFlowerSelected;

  const FlowerGallery({
    Key? key,
    required this.flowers,
    this.onFlowerSelected,
  }) : super(key: key);

  @override
  State<FlowerGallery> createState() => _FlowerGalleryState();
}

class _FlowerGalleryState extends State<FlowerGallery> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 4),
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            itemCount: (widget.flowers.length / 2).ceil(),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, pageIndex) {
              return Row(
                children: [
                  for (int i = 0; i < 2; i++)
                    if (pageIndex * 2 + i < widget.flowers.length)
                      Expanded(
                        child: FlowerCard(
                          flower: widget.flowers[pageIndex * 2 + i],
                          onTap: widget.onFlowerSelected != null
                              ? () => widget.onFlowerSelected!(
                                  widget.flowers[pageIndex * 2 + i])
                              : null,
                        ),
                      ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            (widget.flowers.length / 2).ceil(),
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? const Color(0xFF4CAF50)
                    : Colors.grey[300],
              ),
            ),
          ),
        ),
      ],
    );
  }
}