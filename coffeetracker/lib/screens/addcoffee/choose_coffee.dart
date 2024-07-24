import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_purchased_coffee.dart';
import 'add_homemade_coffee.dart';
import 'add_coffee_vending_machine.dart';
import 'package:coffeetracker/screens/addcoffee/favorite_coffee.dart';
import 'package:flutter/services.dart';

class NoTransitionPageRoute<T> extends MaterialPageRoute<T> {
  NoTransitionPageRoute({required WidgetBuilder builder}) : super(builder: builder);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

class ChooseCoffee extends StatefulWidget {
  const ChooseCoffee({super.key});

  @override
  _ChooseCoffeeState createState() => _ChooseCoffeeState();
}

class _ChooseCoffeeState extends State<ChooseCoffee> {
  @override
  void initState() {
    super.initState();
    // Set preferred orientations to portrait mode
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    // Reset preferred orientations to allow both portrait and landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Coffee',
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 30.0,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), 
              children: [
                _buildCoffeeTypeButton(context, 'Homemade Coffee', 'assets/latte.png', _navigateToHomemadeCoffee),
                _buildCoffeeTypeButton(context, 'Purchased Coffee', 'assets/coffee-cup.png', _navigateToPurchasedCoffee),
                _buildCoffeeTypeButton(context, 'Coffee Vending Machine', 'assets/coffee-machine.png', _navigateToVendingCoffeeMachine),
                _buildCoffeeTypeButton(context, 'Favourite Coffees', 'assets/favourite.png', _navigateToFavouriteCoffee),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoffeeTypeButton(BuildContext context, String title, String imagePath, Function(BuildContext) onTap) {
    return InkWell(
      onTap: () => onTap(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            child: Image.asset(imagePath, width: 90, height: 90),
          ),
          const SizedBox(height: 5.0),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToHomemadeCoffee(BuildContext context) {
    Navigator.push(
      context,
      NoTransitionPageRoute(builder: (context) => const AddHomemadeCoffee()),
    );
  }

  void _navigateToPurchasedCoffee(BuildContext context) {
    Navigator.push(
      context,
      NoTransitionPageRoute(builder: (context) => const AddPurchasedCoffee()),
    );
  }

  void _navigateToVendingCoffeeMachine(BuildContext context) {
    Navigator.push(
      context,
      NoTransitionPageRoute(builder: (context) => const AddCoffeeVendingMachine()),
    );
  }

  void _navigateToFavouriteCoffee(BuildContext context) {
    Navigator.push(
      context,
      NoTransitionPageRoute(builder: (context) => FavoriteCoffeesPage()),
    );
  }
}
