import 'package:flutter/material.dart';
import '../services/phrase_storage.dart';
import '../services/platform_bridge.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _bubbleSize;
  late double _opacity;
  late bool _smartDeduplication;
  late bool _autoCloseOnTap;

  @override
  void initState() {
    super.initState();
    final settings = PhraseStorage.instance.bubbleSettings;
    _bubbleSize = settings['bubbleSize'] as String? ?? 'Medium';
    _opacity = (settings['bubbleOpacity'] as num?)?.toDouble() ?? 0.9;
    _smartDeduplication = settings['smartDeduplication'] as bool? ?? true;
    _autoCloseOnTap = settings['autoCloseOnTap'] as bool? ?? true;
  }

  Future<void> _saveSettings() async {
    await PhraseStorage.instance.updateSettings({
      'bubbleSize': _bubbleSize,
      'bubbleOpacity': _opacity,
      'smartDeduplication': _smartDeduplication,
      'autoCloseOnTap': _autoCloseOnTap,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13131A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131A),
        elevation: 0,
        title: const Text('Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Smart Conversation Memory'),
          _buildCard(
            children: [
              SwitchListTile(
                title: const Text('Smart Category Filtering', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text(
                  'Once you use an opener or small talk phrase in a conversation, hide it from the floating palette for that chat session.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: _smartDeduplication,
                activeColor: const Color(0xFF6366F1),
                onChanged: (val) {
                  setState(() => _smartDeduplication = val);
                  _saveSettings();
                },
              ),
              const Divider(color: Colors.white10),
              ListTile(
                title: const Text('Clear Chat Memory Cache', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text(
                  'Reset remembered categories and phrases for all active chats',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                trailing: TextButton(
                  onPressed: () async {
                    await PlatformBridge.instance.resetSmartHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat memory cache cleared!')),
                      );
                    }
                  },
                  child: const Text('Reset', style: TextStyle(color: Color(0xFF818CF8))),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('Floating Bubble Customization'),
          _buildCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Bubble Size', style: TextStyle(color: Colors.white, fontSize: 14)),
                    DropdownButton<String>(
                      value: _bubbleSize,
                      dropdownColor: const Color(0xFF26283B),
                      underline: const SizedBox(),
                      style: const TextStyle(color: Colors.white),
                      items: ['Small', 'Medium', 'Large'].map((s) {
                        return DropdownMenuItem(value: s, child: Text(s));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _bubbleSize = val);
                          _saveSettings();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bubble & Palette Opacity', style: TextStyle(color: Colors.white, fontSize: 14)),
                        Text('${(_opacity * 100).toInt()}%', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    Slider(
                      value: _opacity,
                      min: 0.4,
                      max: 1.0,
                      divisions: 6,
                      activeColor: const Color(0xFF6366F1),
                      onChanged: (val) {
                        setState(() => _opacity = val);
                        _saveSettings();
                      },
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white10),
              SwitchListTile(
                title: const Text('Auto-close Palette', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text(
                  'Automatically collapse the floating palette after tapping a phrase to inject.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                value: _autoCloseOnTap,
                activeColor: const Color(0xFF6366F1),
                onChanged: (val) {
                  setState(() => _autoCloseOnTap = val);
                  _saveSettings();
                },
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildSectionHeader('System Permissions'),
          _buildCard(
            children: [
              ListTile(
                leading: const Icon(Icons.layers_outlined, color: Color(0xFF6366F1)),
                title: const Text('Display Over Other Apps', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Settings > Apps > Special app access', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => PlatformBridge.instance.openOverlaySettings(),
              ),
              const Divider(color: Colors.white10),
              ListTile(
                leading: const Icon(Icons.accessibility_new, color: Color(0xFF10B981)),
                title: const Text('Accessibility Service', style: TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: const Text('Settings > Accessibility > QuickFlow', style: TextStyle(color: Colors.white54, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => PlatformBridge.instance.openAccessibilitySettings(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF818CF8),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1F2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: children),
    );
  }
}
