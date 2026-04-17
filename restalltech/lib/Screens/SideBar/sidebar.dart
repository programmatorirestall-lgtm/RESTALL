import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_platform_alert/flutter_platform_alert.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:restalltech/API/Logout/logout.dart';
import 'package:restalltech/API/PhotoPic/photoPic.dart';
import 'package:restalltech/API/Ticket/ticket.dart';
import 'package:restalltech/API/UserData/userData.dart';
import 'package:restalltech/Screens/AddTech/add_tech_screen.dart';
import 'package:restalltech/Screens/AddTech/components/add_tech_form.dart';
import 'package:restalltech/Screens/Home/components/home_admin.dart';
import 'package:restalltech/Screens/Home/components/home_tech.dart';
import 'package:restalltech/Screens/ListTech/listTech.dart';
import 'package:restalltech/Screens/LoadingGoods/LoadingGoodsScreen.dart';
import 'package:restalltech/Screens/LoadingGoods/components/loadingGoods.dart';

import 'package:restalltech/Screens/OpenTicket/ticket_screen.dart';
import 'package:restalltech/Screens/Preventivi/preventivi.dart';
import 'package:restalltech/Screens/PriceProduct/PriceProductScreen.dart';
import 'package:restalltech/Screens/PriceProduct/components/priceProduct.dart';
import 'package:restalltech/Screens/Settings/settings_screen.dart';
import 'package:restalltech/Screens/UnloadingGoods/UnloadingGoodsScreen.dart';
import 'package:restalltech/Screens/UnloadingGoods/components/body.dart';
import 'package:restalltech/Screens/WareHouse/components/warehouse.dart';
import 'package:restalltech/Screens/WareHouse/warehouseScreen.dart';
import 'package:restalltech/Screens/Welcome/welcome_screen.dart';
import 'package:restalltech/Screens/closedTicket/closed_admin.dart';
import 'package:restalltech/Screens/closedTicket/my_closed_ticket_screen.dart';
import 'package:restalltech/Screens/myTickets/components/my_ticket.dart';
import 'package:restalltech/Screens/myTickets/my_ticket_screen.dart';
import 'package:restalltech/Screens/profile/profile_screen.dart';
import 'package:restalltech/constants.dart';
import 'package:restalltech/main.dart';
import 'package:restalltech/models/invoice.dart';
import 'package:restalltech/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:http/http.dart' as http;

class SideBar extends StatefulWidget {
  const SideBar({super.key});

  @override
  State<SideBar> createState() => _SideBarState();
}

final _key = GlobalKey<ScaffoldState>();
late String _ragSoc = "";
late String _userType = "";
//User userData = getUserData() as User;

class _SideBarState extends State<SideBar> {
  final _controller = SidebarXController(selectedIndex: 0, extended: true);
  String title = "Home";
  @override
  void initState() {
    super.initState();
    _controller.addListener(setTitle);
    _controller.addListener(_loadUserData);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt') as String;
      if (token != null) {
        final decodedToken = Jwt.parseJwt(token);
        final ragSoc = decodedToken['nome'];
        final tipo = decodedToken['type'];
        setState(() {
          _ragSoc = ragSoc;
          _userType = tipo;
        });
      }
    } on Error {
      FlutterPlatformAlert.showAlert(
        windowTitle: 'Si è verificato un errore',
        text: 'Se continua a verificarsi contatta lo sviluppatore.',
        alertStyle: AlertButtonStyle.ok,
        iconStyle: IconStyle.error,
      );
    }
  }

  setTitle() {
    setState(() {
      title = _getTitleByIndex(_controller.selectedIndex);
    });
  }

  setTitleByString(String t) {
    setState(() {
      title = t;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // Here !
        DefaultWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('it')],
      title: "RestAll",
      debugShowCheckedModeBanner: false,
      theme: appBartheme(),
      home: Builder(
        builder: (context) {
          final isSmallScreen = MediaQuery.of(context).size.width < 800;
          return Scaffold(
            //backgroundColor: kPrimaryLightColor,
            key: _key,
            appBar: isSmallScreen
                ? AppBar(
                    backgroundColor: appBarColor,
                    title: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: IconButton(
                      color: primaryColor,
                      onPressed: () {
                        // if (!Platform.isAndroid && !Platform.isIOS) {
                        //   _controller.setExtended(true);
                        // }
                        _key.currentState?.openDrawer();
                      },
                      icon: const Icon(Icons.menu),
                    ),
                  )
                : null,
            drawer: RestAllSidebarX(controller: _controller),
            body: Row(
              children: [
                if (!isSmallScreen) RestAllSidebarX(controller: _controller),
                Expanded(
                  child: Center(
                    child: _Screens(
                      controller: _controller,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class RestAllSidebarX extends StatelessWidget {
  const RestAllSidebarX({
    Key? key,
    required SidebarXController controller,
  })  : _controller = controller,
        super(key: key);

  final SidebarXController _controller;

  // Avatar animato con shimmer, fallback e refresh
  Future<String?> getImage() async {
    try {
      final res = await PhotoPicApi().getPhotoPic();
      final body = json.decode(res.body);
      var img = body['file'];
      String? imageUrl = img?['location'];
      if (imageUrl == null || imageUrl.isEmpty) return null;
      var cacheManager = DefaultCacheManager();
      FileInfo? fileInfo = await cacheManager.getFileFromCache(imageUrl);
      if (fileInfo == null) {
        var response = await http.get(Uri.parse(imageUrl));
        if (response.statusCode == 200) {
          fileInfo = (await cacheManager.putFile(imageUrl, response.bodyBytes))
              as FileInfo?;
        }
      }
      return fileInfo?.file.path;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color.fromARGB(255, 248, 250, 255)],
          ),
          borderRadius: BorderRadius.only(
              topRight: Radius.circular(30), bottomRight: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        hoverColor: primaryColor.withOpacity(0.1),
        hoverTextStyle: const TextStyle(
          color: secondaryColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        textStyle: TextStyle(
          color: secondaryColor.withOpacity(0.7),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        selectedTextStyle: const TextStyle(
          color: secondaryColor,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
        itemTextPadding: const EdgeInsets.only(left: 25),
        selectedItemTextPadding: const EdgeInsets.only(left: 25),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.transparent),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor.withOpacity(0.8), primaryColor],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        hoverIconTheme: const IconThemeData(
          color: secondaryColor,
          size: 22,
        ),
        iconTheme: IconThemeData(
          color: secondaryColor.withOpacity(0.7),
          size: 22,
        ),
        selectedIconTheme: const IconThemeData(
          color: secondaryColor,
          size: 22,
        ),
      ),
      extendedTheme: SidebarXTheme(
        width: 220,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color.fromARGB(255, 248, 250, 255)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
      ),
      headerBuilder: (context, extended) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ));
                  },
                  child: FutureBuilder<String?>(
                    future: getImage(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.hasData &&
                          snapshot.data != null) {
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 800),
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    maxRadius: 50,
                                    backgroundImage:
                                        FileImage(File(snapshot.data!)),
                                    backgroundColor: Colors.grey[50],
                                  ),
                                  Positioned(
                                    bottom: 4,
                                    right: 4,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: successColor,
                                        border:
                                            Border.all(color: white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      } else {
                        return SizedBox(
                          height: 100,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundColor: white,
                                  backgroundImage: const AssetImage(
                                      "assets/images/logo.png"),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: successColor,
                                      border:
                                          Border.all(color: white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedOpacity(
                  opacity: extended ? 1.0 : 0.0,
                  duration: Duration(milliseconds: extended ? 600 : 200),
                  child: Text(
                    _ragSoc,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: secondaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedOpacity(
                  opacity: extended ? 1.0 : 0.0,
                  duration: Duration(milliseconds: extended ? 800 : 200),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: kPrimaryLightColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Benvenuto!',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      items: userType(context),
    );
  }

  _logout() {
    LogoutApi().logout();
  }

  SidebarXItem logout(context) {
    return SidebarXItem(
      iconWidget: const Icon(
        Icons.logout_rounded,
        color: Colors.red,
      ),
      label: 'Esci',
      onTap: () {
        _logout();
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(
          builder: (context) {
            return const WelecomeScreen();
          },
        ), ModalRoute.withName("../"));
      },
    );
  }

  List<SidebarXItem> userType(context) {
    if (_userType == "admin") {
      return ([
        SidebarXItem(
          icon: Icons.home,
          label: 'Home',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.engineering_rounded,
          label: 'Tecnici',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.handshake_rounded,
          label: 'Preventivi',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.history_rounded,
          label: 'Ticket Chiusi',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.add_rounded,
          label: 'Apri Ticket',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.warehouse_rounded,
          label: 'Magazzino',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.settings_rounded,
          label: 'Impostazioni',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        logout(context)
      ]);
    } else if (_userType == "tech") {
      return ([
        SidebarXItem(
          icon: Icons.handyman_rounded,
          label: 'Assegnazioni',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.history_rounded,
          label: 'Ticket Chiusi',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.euro_rounded,
          label: 'Prezzi',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.upload_rounded,
          label: 'Prelievo',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        SidebarXItem(
          icon: Icons.download_rounded,
          label: 'Reso',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        ),
        logout(context)
      ]);
    } else {
      return ([
        SidebarXItem(
          icon: Icons.home,
          label: 'Home',
          onTap: () {
            _key.currentState?.closeDrawer();
          },
        )
      ]);
    }
  }
}

class _Screens extends StatelessWidget {
  const _Screens({
    Key? key,
    required this.controller,
  }) : super(key: key);

  final SidebarXController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        String title = _getTitleByIndex(controller.selectedIndex);
        if (_userType == "admin") {
          switch (controller.selectedIndex) {
            case 0:
              return const HomeAdmin();
            case 1:
              return const ListTech();
            case 2:
              return const PreventiviManager();

            case 3:
              return const ClosedTicket();
            case 4:
              return const TicketScreen();
            case 5:
              return const WareHouse();
            case 6:
              return const SettingsScreen();

            default:
              return Text(
                title,
                style: theme.textTheme.headlineSmall,
              );
          }
        } else if (_userType == "tech") {
          switch (controller.selectedIndex) {
            case 0:
              return const MyTicketScreen();

            case 1:
              return const MyClosedTicketScreen();
            case 2:
              return const PriceProductScreen();
            case 3:
              return const LoadingGoodsScreen();
            case 4:
              return const UnloadingGoodsScreen();
            default:
              return Text(
                title,
                style: theme.textTheme.headlineSmall,
              );
          }
        } else {
          return const Text("Accesso Negato");
        }
      },
    );
  }
}

class Lista extends StatelessWidget {
  const Lista({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 10),
      itemBuilder: (context, index) => Container(
        height: 100,
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10, right: 10, left: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Theme.of(context).canvasColor,
          boxShadow: const [BoxShadow()],
        ),
      ),
    );
  }
}

String _getTitleByIndex(int index) {
  if (_userType == "admin") {
    switch (index) {
      case 0:
        return 'Home';

      case 1:
        return 'Tecnici';
      case 2:
        return 'Preventivi';
      case 3:
        return 'Ticket Chiusi';
      case 4:
        return 'Apri Ticket';

      case 5:
        return 'Magazzino';
      case 6:
        return 'Impostazioni';
      default:
        return 'Pagina non trovata';
    }
  } else if (_userType == "tech") {
    switch (index) {
      case 0:
        return 'Assegnazioni';
      case 1:
        return 'Ticket Chiusi';
      case 2:
        return 'Prezzi';
      case 3:
        return 'Prelievo';
      case 4:
        return 'Reso';
      default:
        return 'Pagina non trovata';
    }
  } else {
    return 'undefined';
  }
}
