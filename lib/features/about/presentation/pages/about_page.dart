import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About & How to Use", 
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 2,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: Colors.white,
                child: TabBar(
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).primaryColor,
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.info_outline),
                      text: "About",
                    ),
                    Tab(
                      icon: Icon(Icons.help_outline),
                      text: "How to Use",
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // About Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, "About This App"),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            context,
                            "CSS SPEECH ANALYZER",
                            "This application is designed for audio recording, playback, and advanced analysis. It provides tools for recording audio, visualizing waveforms, and analyzing pitch and intensity patterns in speech recordings.",
                            Icons.music_note,
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, "Key Features"),
                          const SizedBox(height: 16),
                          _buildFeatureItem(context, "Audio Recording", "Record audio with pause/resume functionality and save recordings for later analysis."),
                          _buildFeatureItem(context, "Audio Playback", "Play back recordings with visualization of the audio waveform."),
                          _buildFeatureItem(context, "Pitch Analysis", "Analyze and visualize pitch patterns in speech recordings with customizable range selection (0-500 Hz default)."),
                          _buildFeatureItem(context, "Intensity Analysis", "Analyze and visualize intensity patterns in speech recordings with customizable range selection (-60-0 dB default)."),
                          _buildFeatureItem(context, "Range Selection", "Customize pitch and intensity ranges using sliders or precise text input for detailed analysis."),
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, "Technical Information"),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            context,
                            "Version",
                            "1.0.0",
                            Icons.numbers,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            context,
                            "Developed with",
                            "Flutter Framework",
                            Icons.code,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            context,
                            "Designed by",
                            "PROF. CHANDER SHEKHAR SINGH,\nDEPARTMENT OF LINGUISTICS,\nRAJDHANI COLLEGE, UNIVERSITY OF DELHI",
                            Icons.person,
                          ),
                        ],
                      ),
                    ),
                    
                    // How to Use Tab
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle(context, "Getting Started"),
                          const SizedBox(height: 16),
                          _buildInstructionStep(
                            context,
                            "1",
                            "Recording Audio",
                            "On the home screen, press the microphone button to start recording. Use the pause button to pause/resume and the stop button to end recording. Your recordings will appear in the list on the right side.",
                            Icons.mic,
                          ),
                          _buildInstructionStep(
                            context,
                            "2",
                            "Importing Audio",
                            "Use the upload button to import existing audio files from your device. Supported formats include MP3, WAV, M4A, and PCM.",
                            Icons.upload_file,
                          ),
                          _buildInstructionStep(
                            context,
                            "3",
                            "Playing Recordings",
                            "Tap on any recording in the list to open the playback screen. You can play, pause, and navigate through the audio using the playback controls.",
                            Icons.play_circle,
                          ),
                          _buildInstructionStep(
                            context,
                            "4",
                            "Analyzing Audio",
                            "From the playback screen, you can access pitch and intensity analysis features to visualize speech patterns.",
                            Icons.analytics,
                          ),
                          const SizedBox(height: 24),
                          _buildSectionTitle(context, "Using Analysis Features"),
                          const SizedBox(height: 16),
                          _buildInstructionStep(
                            context,
                            "1",
                            "Pitch Analysis",
                            "View pitch patterns over time. Use the range selectors to focus on specific frequency ranges (0-500 Hz by default).",
                            Icons.show_chart,
                          ),
                          _buildInstructionStep(
                            context,
                            "2",
                            "Intensity Analysis",
                            "View intensity (volume) patterns over time. Use the range selectors to focus on specific intensity ranges (-60-0 dB by default).",
                            Icons.equalizer,
                          ),
                          _buildInstructionStep(
                            context,
                            "3",
                            "Customizing Ranges",
                            "Use the sliders to adjust the visible range of data. For more precise control, open the drawer to enter exact minimum and maximum values for both pitch and intensity ranges.",
                            Icons.tune,
                          ),
                          _buildInstructionStep(
                            context,
                            "4",
                            "Resetting to Defaults",
                            "Use the reset buttons in the drawer to return to default range values (0-500 Hz for pitch, -60-0 dB for intensity).",
                            Icons.restore,
                          ),
                        ],
                      ),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String content, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionStep(BuildContext context, String step, String title, String description, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
