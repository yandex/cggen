#!/usr/bin/swift

import Foundation

func perform(_ command: String) {
  perform(command.components(separatedBy: " "))
}

func perform(_ command: [String]) {
  guard !command.isEmpty else {
    return
  }

  let task = Process()
  task.launchPath = command[0]
  task.arguments = Array(command.dropFirst())
  task.environment = ProcessInfo.processInfo.environment
  task.launch()
  task.waitUntilExit()
}

try? FileManager().createDirectory(
  atPath: ".build",
  withIntermediateDirectories: false
)

let fd = fopen(".build/.build_lock", "w")!
lockf(Int32(fd.pointee._file), F_LOCK, 0)
perform("/usr/bin/swift build -c release --product cggen")
lockf(Int32(fd.pointee._file), F_ULOCK, 0)
fclose(fd)
