import Foundation
import AVFoundation
@preconcurrency import ScreenCaptureKit
import CoreMedia

@main
struct SystemAudioDump {
  static func main() async {
    do {
      print("Starting SystemAudioDump...")
      
      // Check if we have screen recording permission
      print("Checking permissions...")
      let canRecord = CGPreflightScreenCaptureAccess()
      if !canRecord {
        print("❌ Screen recording permission required!")
        print("Please go to System Preferences > Security & Privacy > Privacy > Screen Recording")
        print("and enable access for this application.")
        
        // Request permission
        let granted = CGRequestScreenCaptureAccess()
        if !granted {
          print("Permission denied. Exiting.")
          exit(1)
        }
      }
      print("✅ Permissions OK")
      
      // 1) Grab shareable content
      print("Getting shareable content...")
      let content = try await SCShareableContent.excludingDesktopWindows(false,
                                                                        onScreenWindowsOnly: true)
      guard let display = content.displays.first else {
        fatalError("No display found")
      }
      print("Found display: \(display)")

      // 2) Build a filter for that display (video is ignored below)
      let filter = SCContentFilter(display: display,
                                   excludingApplications: [], // don't exclude any
                                   exceptingWindows: [])
      print("Created filter")

      // 3) Build a stream config that only captures audio
      let cfg = SCStreamConfiguration()
      cfg.capturesAudio = true
      cfg.captureMicrophone = false
      cfg.excludesCurrentProcessAudio = true  // don't capture our own output
      print("Created configuration")

      // 4) Create and start the stream
      let dumper = AudioDumper()
      let stream = SCStream(filter: filter,
                            configuration: cfg,
                            delegate: dumper)
      print("Created stream")

      // only install audio output
      try stream.addStreamOutput(dumper,
                                 type: .audio,
                                 sampleHandlerQueue: DispatchQueue(label: "audio"))
      print("Added stream output")
      
      try await stream.startCapture()
      print("Started capture")

      await MainActor.run {
        print("✅ Capturing system audio. Press ⌃C to stop.", to: &standardError)
      }
      
      // keep the process alive with a safer approach
      print("Entering main loop...")
      
      // Set up signal handling for graceful shutdown
      signal(SIGINT) { _ in
        print("Received SIGINT, shutting down...")
        exit(0)
      }
      
      // Keep alive with a simple loop instead of dispatchMain
      while true {
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
      }

    } catch {
      fputs("Error: \(error)\n", Darwin.stderr)
      exit(1)
    }
  }
}

/// A simple SCStreamOutput + SCStreamDelegate that converts to 24 kHz Int16 PCM and writes to stdout
final class AudioDumper: NSObject, SCStreamDelegate, SCStreamOutput {
  // We'll hold a converter from native rate to 24 kHz, 16-bit, interleaved.
  private var converter: AVAudioConverter?
  private var outputFormat: AVAudioFormat?

  func stream(_ stream: SCStream,
              didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
              of outputType: SCStreamOutputType) {
    print("Received audio sample")
    guard outputType == .audio else { return }

    // For now, let's just skip the complex audio processing to see if we can avoid the crash
    print("Processing audio sample with \(sampleBuffer.numSamples) samples")
    
    // Simple test - just write some dummy data
)
    FileHandle.standardOutput.write(dummyData)
  }
  
  func stream(_ stream: SCStream, didStopWithError error: Error) {
    fputs("Stream stopped with error: \(error)\n", Darwin.stderr)
  }
}

// Helper to print to stderr
@MainActor var standardError = FileHandle.standardError
extension FileHandle: @retroactive TextOutputStream {
  public func write(_ string: String) {
    if let data = string.data(using: .utf8) {
      self.write(data)
    }
  }
}
