#!/usr/bin/swift

import Foundation

func perform(_ command: String) -> Int32 {
  perform(command.components(separatedBy: " "))
}

func perform(_ command: [String]) -> Int32 {
  guard !command.isEmpty else {
    return 1
  }

  let task = Process()
  task.launchPath = command[0]
  task.arguments = Array(command.dropFirst())
  task.environment = ProcessInfo.processInfo.environment
  task.launch()
  task.waitUntilExit()
  return task.terminationStatus
}

try? FileManager().createDirectory(
  atPath: ".build",
  withIntermediateDirectories: false
)

let fd = fopen(".build/.build_lock", "w")!
lockf(Int32(fd.pointee._file), F_LOCK, 0)
let returnCode = perform("/usr/bin/swift build -c debug --product cggen")
lockf(Int32(fd.pointee._file), F_ULOCK, 0)
fclose(fd)
exit(returnCode)
