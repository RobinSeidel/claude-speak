// Speaks text with a macOS Personal Voice, which `say` cannot use.
// usage: speak-pv [-r wordsPerMinute] -v <voice name>   (text on stdin)
import AVFoundation

final class Done: NSObject, AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didFinish u: AVSpeechUtterance) { exit(0) }
    func speechSynthesizer(_ s: AVSpeechSynthesizer, didCancel u: AVSpeechUtterance) { exit(0) }
}

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data("speak-pv: \(message)\n".utf8))
    exit(1)
}

var voiceName: String?
var wpm: Double?
var args = CommandLine.arguments.dropFirst()
while let arg = args.popFirst() {
    switch arg {
    case "-v": voiceName = args.popFirst()
    case "-r": wpm = args.popFirst().flatMap(Double.init)
    default: fail("unknown argument \(arg)")
    }
}
guard let voiceName else { fail("missing -v <voice name>") }

let text = String(decoding: FileHandle.standardInput.readDataToEndOfFile(), as: UTF8.self)
guard !text.isEmpty else { exit(0) }

// The authorization callback never fires in a command-line tool, so only ask
// (and wait) when access has not been decided yet; otherwise start speaking now.
if AVSpeechSynthesizer.personalVoiceAuthorizationStatus == .notDetermined {
    let auth = DispatchSemaphore(value: 0)
    AVSpeechSynthesizer.requestPersonalVoiceAuthorization { _ in auth.signal() }
    _ = auth.wait(timeout: .now() + 30)
}

guard let voice = AVSpeechSynthesisVoice.speechVoices().first(where: {
    $0.voiceTraits.contains(.isPersonalVoice) && $0.name == voiceName
}) else { fail("no Personal Voice named \(voiceName) (is access allowed in Settings → Accessibility → Personal Voice?)") }

let utterance = AVSpeechUtterance(string: text)
utterance.voice = voice
// `say -r` takes words per minute; AVSpeech's 0.5 default is roughly 180 wpm.
if let wpm { utterance.rate = Float(min(max(0.5 * wpm / 180, 0.1), 1.0)) }

let delegate = Done()
let synth = AVSpeechSynthesizer()
synth.delegate = delegate
synth.speak(utterance)
RunLoop.main.run()
