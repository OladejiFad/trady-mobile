import '../models/bargain_model.dart';

Map<String, dynamic> getAcceptedItemsAndPrice(Bargain bargain) {
  print("🔍 Checking accepted items for bargain ${bargain.id}, status = ${bargain.status}");

  final buyerOffers = bargain.buyerOffers ?? [];
  final sellerOffers = bargain.sellerOffers ?? [];

  // Combine both offers with type tagging
  final allOffers = [
    ...buyerOffers.map((o) => {
          'items': o.items,
          'price': o.totalOfferedPrice,
          'time': o.time,
          'source': 'buyer',
        }),
    ...sellerOffers.map((o) => {
          'items': o.items,
          'price': o.totalCounterPrice,
          'time': o.time,
          'source': 'seller',
        }),
  ];

  if (allOffers.isEmpty) {
    print("⚠️ No offers at all");
    return {'items': <BargainItem>[], 'price': bargain.acceptedPrice ?? 0.0};
  }

  // Sort by time
  allOffers.sort((a, b) => (a['time'] as DateTime).compareTo(b['time'] as DateTime));

  final last = allOffers.last;
  print("✅ Accepted — last offer before acceptance was from ${last['source']} at ₦${last['price']}");

  return {
    'items': last['items'],
    'price': last['price'],
  };
}
