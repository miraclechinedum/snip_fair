import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/buttons/custom_button.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:video_player/video_player.dart';

@RoutePage()
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(
        'https://snipfair.com/videos/horizontal.mp4',
      ), // Replace with your video's URL
    )..initialize().then((_) {
        setState(() {
          _controller
            ..play()
            ..setLooping(true) // Loop the video
            ..setVolume(0); // Play silently in the background
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<AppCubit>();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          // Background Video
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black],
              ),
            ),
          ),
          // Onboarding Content (e.g., text, buttons)
          Center(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const AppText(
                      text: 'Your On-Demand \nBeauty Pro',
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                    const AppText(
                      text:
                          'Connect with professional stylists in your area. Book hair, nails, makeup, and grooming services at your convenience.',
                      color: Colors.white,
                    ),
                    20.verticalSpace,
                    CustomButton(
                      onPressed: () {
                        context.router.push(LoginRoute());
                      },
                      title: 'Book an Appointment',
                    ),
                    12.verticalSpace,
                    if (cubit.state.platformSettings
                            ?.allowRegistrationStylists ??
                        false)
                      CustomButton(
                        title: 'Continue as Stylist',
                        onPressed: () {
                          context.router.push(LoginRoute(isStylist: true));
                        },
                        gradient: null,
                        textColor: Colors.black,
                        background: Colors.white,
                      ),
                    12.verticalSpace,
                    CustomButton(
                      title: 'Customer Guest Mode',
                      onPressed: cubit.setGuestUser,
                      gradient: null,
                      isOutline: true,
                      background: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
