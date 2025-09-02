import 'package:flutter/material.dart';
import '../models/user.dart';

class AdvertisementCarousel
    extends
        StatefulWidget {
  final List<
    User
  >
  businessesWithAds;
  final Function(
    User,
  )
  onBusinessTap;

  const AdvertisementCarousel({
    super.key,
    required this.businessesWithAds,
    required this.onBusinessTap,
  });

  @override
  State<
    AdvertisementCarousel
  >
  createState() =>
      _AdvertisementCarouselState();
}

class _AdvertisementCarouselState
    extends
        State<
          AdvertisementCarousel
        > {
  final PageController _pageController =
      PageController();
  int _currentIndex =
      0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (widget.businessesWithAds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height:
          200,
      margin: const EdgeInsets.all(
        16,
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.campaign,
                color:
                    Colors.blue,
              ),
              const SizedBox(
                width:
                    8,
              ),
              const Text(
                'Nearby Advertisements',
                style: TextStyle(
                  fontSize:
                      16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_currentIndex + 1}/${widget.businessesWithAds.length}',
                style: const TextStyle(
                  fontSize:
                      12,
                  color:
                      Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(
            height:
                8,
          ),

          // Carousel
          Expanded(
            child: PageView.builder(
              controller:
                  _pageController,
              onPageChanged: (
                index,
              ) {
                setState(
                  () {
                    _currentIndex =
                        index;
                  },
                );
              },
              itemCount:
                  widget.businessesWithAds.length,
              itemBuilder: (
                context,
                index,
              ) {
                final business =
                    widget.businessesWithAds[index];
                return _buildAdvertisementCard(
                  business,
                );
              },
            ),
          ),

          // Dots indicator
          if (widget.businessesWithAds.length >
              1) ...[
            const SizedBox(
              height:
                  8,
            ),
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: List.generate(
                widget.businessesWithAds.length,
                (
                  index,
                ) => Container(
                  width:
                      8,
                  height:
                      8,
                  margin: const EdgeInsets.symmetric(
                    horizontal:
                        4,
                  ),
                  decoration: BoxDecoration(
                    shape:
                        BoxShape.circle,
                    color:
                        _currentIndex ==
                                index
                            ? Colors.blue
                            : Colors.grey.shade300,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvertisementCard(
    User business,
  ) {
    return GestureDetector(
      onTap:
          () => widget.onBusinessTap(
            business,
          ),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal:
              4,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            12,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                0.1,
              ),
              blurRadius:
                  8,
              offset: const Offset(
                0,
                4,
              ),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            12,
          ),
          child: Stack(
            children: [
              // Background Image
              if (business.advertisementImageUrl !=
                  null)
                Container(
                  width:
                      double.infinity,
                  height:
                      double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(
                        business.advertisementImageUrl!,
                      ),
                      fit:
                          BoxFit.cover,
                      onError: (
                        exception,
                        stackTrace,
                      ) {
                        // Handle image loading error
                      },
                    ),
                  ),
                )
              else
                Container(
                  width:
                      double.infinity,
                  height:
                      double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin:
                          Alignment.topLeft,
                      end:
                          Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade400,
                        Colors.purple.shade400,
                      ],
                    ),
                  ),
                ),

              // Gradient overlay for better text readability
              Container(
                width:
                    double.infinity,
                height:
                    double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin:
                        Alignment.topCenter,
                    end:
                        Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(
                        0.7,
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(
                  16,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // Business name and profile
                      Row(
                        children: [
                          // Profile picture/emoji
                          Container(
                            width:
                                40,
                            height:
                                40,
                            decoration: BoxDecoration(
                              shape:
                                  BoxShape.circle,
                              color: Colors.white.withOpacity(
                                0.9,
                              ),
                            ),
                            child:
                                business.profilePictureUrl !=
                                        null
                                    ? ClipOval(
                                      child: Image.network(
                                        business.profilePictureUrl!,
                                        width:
                                            40,
                                        height:
                                            40,
                                        fit:
                                            BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return Center(
                                            child: Text(
                                              business.profileEmoji ??
                                                  '🏢',
                                              style: const TextStyle(
                                                fontSize:
                                                    20,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                    : Center(
                                      child: Text(
                                        business.profileEmoji ??
                                            '🏢',
                                        style: const TextStyle(
                                          fontSize:
                                              20,
                                        ),
                                      ),
                                    ),
                          ),
                          const SizedBox(
                            width:
                                12,
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  business.businessName ??
                                      'Business',
                                  style: const TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize:
                                        16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                if (business.advertisementTitle !=
                                    null)
                                  Text(
                                    business.advertisementTitle!,
                                    style: const TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize:
                                          14,
                                      fontWeight:
                                          FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  8,
                              vertical:
                                  4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Colors.orange,
                              borderRadius: BorderRadius.circular(
                                12,
                              ),
                            ),
                            child: const Text(
                              'AD',
                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    10,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height:
                            12,
                      ),

                      // Advertisement description
                      if (business.advertisementDescription !=
                          null)
                        Text(
                          business.advertisementDescription!,
                          style: const TextStyle(
                            color:
                                Colors.white,
                            fontSize:
                                12,
                          ),
                          maxLines:
                              2,
                          overflow:
                              TextOverflow.ellipsis,
                        ),

                      const SizedBox(
                        height:
                            8,
                      ),

                      // Call to action
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color:
                                Colors.white,
                            size:
                                16,
                          ),
                          const SizedBox(
                            width:
                                4,
                          ),
                          Expanded(
                            child: Text(
                              business.businessAddress ??
                                  'Location not available',
                              style: const TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    11,
                              ),
                              maxLines:
                                  1,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  12,
                              vertical:
                                  6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                0.2,
                              ),
                              borderRadius: BorderRadius.circular(
                                16,
                              ),
                              border: Border.all(
                                color: Colors.white.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            child: const Text(
                              'View Details',
                              style: TextStyle(
                                color:
                                    Colors.white,
                                fontSize:
                                    11,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
