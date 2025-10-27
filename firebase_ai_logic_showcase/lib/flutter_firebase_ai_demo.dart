// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'demos/chat/chat_demo.dart';
import 'demos/chat_nano/chat_nano_demo.dart';
import 'demos/multimodal/multimodal_demo.dart';
import 'demos/live_api/live_api_demo.dart';

class DemoHomeScreen extends StatefulWidget {
  const DemoHomeScreen({super.key});

  @override
  State<DemoHomeScreen> createState() => _DemoHomeScreenState();
}

class _DemoHomeScreenState extends State<DemoHomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ChatDemoNanoState> _chatNanoKey = GlobalKey();
  bool _nanoPickerHasBeenShown = false;

  late final List<Widget> _demoPages;

  @override
  void initState() {
    super.initState();
    _demoPages = <Widget>[
      const ChatDemo(),
      const LiveAPIDemo(),
      const MultimodalDemo(),
      ChatDemoNano(key: _chatNanoKey),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 3 && !_nanoPickerHasBeenShown) {
      _chatNanoKey.currentState?.showModelPicker();
      _nanoPickerHasBeenShown = true;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Use BottomNavigationBar for smaller screens
          return Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: _demoPages,
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                const BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: 'Chat',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.video_chat),
                  label: 'Live API',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.photo_library),
                  label: 'Multimodal',
                ),
                BottomNavigationBarItem(
                  icon: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 24.0,
                      ),
                      text: '🍌',
                    ),
                  ),
                  label: 'Nano Banana',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            ),
          );
        } else {
          // Use NavigationRail for larger screens
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  destinations: <NavigationRailDestination>[
                    const NavigationRailDestination(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      icon: Icon(Icons.chat),
                      label: Text('Chat'),
                    ),
                    const NavigationRailDestination(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      icon: Icon(Icons.video_chat),
                      label: Text('Live API'),
                    ),
                    const NavigationRailDestination(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      icon: Icon(Icons.photo_library),
                      label: Text('Multimodal\nInput', textAlign: TextAlign.center),
                    ),
                    NavigationRailDestination(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      icon: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 24.0,
                          ),
                          text: '🍌',
                        ),
                      ),
                      label: const Text('Nano\nBanana', textAlign: TextAlign.center),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _demoPages,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}