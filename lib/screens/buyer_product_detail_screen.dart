import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../models/review_model.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../global/auth_data.dart';

class BuyerProductDetailScreen extends StatefulWidget {
  final String productId;

  const BuyerProductDetailScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<BuyerProductDetailScreen> createState() => _BuyerProductDetailScreenState();
}

class _BuyerProductDetailScreenState extends State<BuyerProductDetailScreen> {
  double _rating = 5;
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;
  Future<void> _submitReview() async {
  final messageText = _messageController.text.trim();
  if (messageText.isEmpty) {
    print('Review submission aborted: empty message');
    return;
  }

  print('Attempting to submit review for productId=${widget.productId}');
  print('Rating: $_rating');
  print('Message: $messageText');

  setState(() => _isSubmitting = true);
  try {
    await ReviewService.addReview(
      targetId: widget.productId,
      targetType: 'product',
      rating: _rating,
      message: messageText,
    );

    print('Review submitted successfully.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Review submitted successfully!',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    _messageController.clear();
    setState(() {}); // Trigger rebuild to refresh reviews
  } catch (e, stacktrace) {
    print('Failed to submit review: $e');
    print('Stacktrace: $stacktrace');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to submit review: $e',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  } finally {
    setState(() => _isSubmitting = false);
  }
}


 

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final fontScale = screenWidth < 400 ? 0.9 : 1.0; // Responsive font scaling
    final padding = screenWidth < 400 ? 12.0 : 16.0; // Responsive padding

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.teal.shade200,
        title: Text(
          'Product Details',
          style: GoogleFonts.poppins(
            fontSize: 24 * fontScale,
            fontWeight: FontWeight.w700,
            color: Colors.teal.shade800,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.teal.shade800),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.8),
          child: FutureBuilder<Product>(
            future: ProductService.fetchProductById(widget.productId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.teal));
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.poppins(fontSize: 13 * fontScale, color: Colors.red.shade700),
                  ),
                );
              } else if (!snapshot.hasData) {
                return Center(
                  child: Text(
                    'Product not found.',
                    style: GoogleFonts.poppins(fontSize: 13 * fontScale, color: Colors.grey.shade600),
                  ),
                );
              }

              final product = snapshot.data!;
              return SingleChildScrollView(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Product Image
                    // Product Image
AnimatedOpacity(
  opacity: 1.0,
  duration: const Duration(milliseconds: 600),
  child: Container(
    constraints: BoxConstraints(
      maxWidth: screenWidth * 0.4,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.teal.shade700, width: 1.5),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.teal.shade200,
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: AspectRatio(
        aspectRatio: 1.2, // Adjust as needed (1.0 for square, >1.0 for wider)
        child: product.imageUrls.isNotEmpty && product.imageUrls.first != null
            ? Image.network(
                product.imageUrls.first.startsWith('http')
                    ? product.imageUrls.first
                    : 'http://172.20.10.2:5000${product.imageUrls.first}',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade200, Colors.grey.shade300],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade200, Colors.grey.shade300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
              ),
      ),
    ),
  ),
),

                    SizedBox(height: padding),
                    // Product Details
                    Text(
                      product.name,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26 * fontScale,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    SizedBox(height: padding / 2),
                    Text(
                      '₦${product.price.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 22 * fontScale,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: padding / 2),
                    Text(
                      'Category: ${product.category}',
                      style: GoogleFonts.poppins(
                        fontSize: 14 * fontScale,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: padding / 2),
                    Text(
                      'Stock: ${product.stock}',
                      style: GoogleFonts.poppins(
                        fontSize: 14 * fontScale,
                        color: product.stock > 0 ? Colors.green.shade700 : Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: padding),
                    Text(
                      product.description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 13 * fontScale,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: padding * 1.5),
                    Divider(color: Colors.grey.shade300),
                    // Reviews Section
                    Text(
                      'Reviews',
                      style: GoogleFonts.poppins(
                        fontSize: 20 * fontScale,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    SizedBox(height: padding / 2),
                    FutureBuilder<List<Review>>(
                      future: ReviewService.fetchReviews('product', widget.productId),
                      builder: (context, reviewSnapshot) {
                        if (reviewSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.amber));
                        } else if (reviewSnapshot.hasError) {
                          return Text(
                            'Error loading reviews: ${reviewSnapshot.error}',
                            style: GoogleFonts.poppins(fontSize: 13 * fontScale, color: Colors.red.shade700),
                          );
                        } else if (reviewSnapshot.data!.isEmpty) {
                          return Text(
                            'No reviews yet.',
                            style: GoogleFonts.poppins(fontSize: 13 * fontScale, color: Colors.grey.shade600),
                          );
                        }

                        final reviews = reviewSnapshot.data!;
                        return Column(
                          children: reviews.map((r) {
                            return AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 600),
                              child: Card(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                margin: EdgeInsets.symmetric(vertical: padding / 2),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(10),
                                  title: Text(
                                    r.displayBuyerName,

                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade700,
                                      fontSize: 14 * fontScale,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      r.message,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12 * fontScale,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        r.rating.toStringAsFixed(1),
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade700,
                                          fontSize: 13 * fontScale,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    SizedBox(height: padding * 1.5),
                    Divider(color: Colors.grey.shade300),
                    // Review Form
                    Text(
                      'Leave a Review',
                      style: GoogleFonts.poppins(
                        fontSize: 18 * fontScale,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700,
                      ),
                    ),
                    SizedBox(height: padding / 2),
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Your Review',
                        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.amber.shade700, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                      style: GoogleFonts.poppins(color: Colors.grey.shade800, fontSize: 13 * fontScale),
                      maxLines: 3,
                    ),
                    SizedBox(height: padding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Your Rating:',
                          style: GoogleFonts.poppins(
                            fontSize: 14 * fontScale,
                            fontWeight: FontWeight.w500,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() => _rating = (index + 1).toDouble());
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Icon(
                                  index < _rating ? Icons.star : Icons.star_border,
                                  color: Colors.amber.shade700,
                                  size: 24,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                    SizedBox(height: padding),
                    AnimatedScale(
                      scale: _isSubmitting ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.teal.shade200,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        onPressed: _isSubmitting ? null : _submitReview,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.teal.shade700, Colors.teal.shade900],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  'Submit Review',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14 * fontScale,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}