// -----------------------------------------------------------------------------
// ArgParse is an argument-parsing library designed for building elegant
// command line interfaces.
//
// Author: Darren Mulholland <darren@mulholland.xyz>
// License: Public Domain
// Version: 0.4.0
// -----------------------------------------------------------------------------

import Foundation


/// Write a string to standard error.
fileprivate func writeStderr(_ string: String) {
    if let data = string.data(using: .utf8) {
        FileHandle.standardError.write(data)
    }
}


/// Print an error message to standard error and exit.
public func exitError(_ message: String) -> Never {
    writeStderr("Error: " + message + ".\n")
    exit(1)
}


/// Internal enum for classifying option types.
fileprivate enum OptionType {
    case bool, string, integer, double
}


/// Internal class for storing option data.
fileprivate class Option {
    let type: OptionType
    var found = false
    var bools = [Bool]()
    var strings = [String]()
    var integers = [Int]()
    var doubles = [Double]()

    var fallbacks = (
        bool: false,
        string: "",
        int: 0,
        double: 0.0
    )

    init(_ type: OptionType) {
        self.type = type
    }

    func trySet(with arg: String) {
        switch type {
            case .bool:
                break;
            case .string:
                strings.append(arg)
            case .integer:
                if let intVal = Int(arg) {
                    integers.append(intVal)
                } else {
                    exitError("cannot parse \(arg) as an integer")
                }
            case .double:
                if let doubleVal = Double(arg) {
                    doubles.append(doubleVal)
                } else {
                    exitError("cannot parse \(arg) as a floating-point value")
                }
        }
    }
}


/// Internal class for making an array of arguments available as a stream.
fileprivate class ArgStream {
    let args: [String]
    var index = 0

    init(_ args: [String]) {
        self.args = args
    }

    func next() -> String {
        index += 1
        return args[index - 1]
    }

    func hasNext() -> Bool {
        return index < args.count
    }
}


/// An ArgParser instance is responsible for registering options and commands
/// and parsing an input array of raw arguments.
public class ArgParser {
    private var helptext: String?
    private var version: String?
    private var options = [String:Option]()
    private var commands = [String:ArgParser]()
    private var arguments = [String]()
    private var callback: ((ArgParser) -> Void)?
    private var command: String?
    private weak var parent: ArgParser?

    /// Initialize an ArgParser instance, optionally specifying help text
    /// and a version string.
    public init(helptext: String? = nil, version: String? = nil) {
        self.helptext = helptext
        self.version = version
    }


    // ---------------------------------------------------------------------
    // Register options.
    // ---------------------------------------------------------------------


    /// Register a boolean option with a default value of false.
    public func newFlag(_ name: String) {
        let option = Option(OptionType.bool)
        for alias in name.split(separator: " ") {
            options[String(alias)] = option
        }
    }

    /// Register a string option.
    public func newString(_ name: String, fallback: String = "") {
        let option = Option(OptionType.string)
        option.fallbacks.string = fallback
        for alias in name.split(separator: " ") {
            options[String(alias)] = option
        }
    }

    /// Register an integer option.
    public func newInt(_ name: String, fallback: Int = 0) {
        let option = Option(OptionType.integer)
        option.fallbacks.int = fallback
        for alias in name.split(separator: " ") {
            options[String(alias)] = option
        }
    }

    /// Register a floating-point option.
    public func newDouble(_ name: String, fallback: Double = 0.0) {
        let option = Option(OptionType.double)
        option.fallbacks.double = fallback
        for alias in name.split(separator: " ") {
            options[String(alias)] = option
        }
    }


    // ---------------------------------------------------------------------
    // Retrieve option values.
    // ---------------------------------------------------------------------


    // Exits with an error message if 'name' is not a registered option.
    private func getOption(_ name: String) -> Option {
        if let option = options[name] {
            return option
        }
        exitError("'\(name)' is not a registered option")
    }

    /// Returns true if the specified option was found while parsing.
    public func found(_ name: String) -> Bool {
        return getOption(name).found
    }

    /// Returns the value of the specified boolean option.
    public func getFlag(_ name: String) -> Bool {
        let option = getOption(name)
        if let value = option.bools.last {
            return value
        } else {
            return option.fallbacks.bool
        }
    }

    /// Returns the value of the specified string option.
    public func getString(_ name: String) -> String {
        let option = getOption(name)
        if let value = option.strings.last {
            return value
        } else {
            return option.fallbacks.string
        }
    }

    /// Returns the value of the specified integer option.
    public func getInt(_ name: String) -> Int {
        let option = getOption(name)
        if let value = option.integers.last {
            return value
        } else {
            return option.fallbacks.int
        }
    }

    /// Returns the value of the specified floating-point option.
    public func getDouble(_ name: String) -> Double {
        let option = getOption(name)
        if let value = option.doubles.last {
            return value
        } else {
            return option.fallbacks.double
        }
    }

    /// Returns the length of the specified option's list of values.
    public func lenList(_ name: String) -> Int {
        let option = getOption(name)
        switch option.type {
            case .bool:
                return option.bools.count
            case .string:
                return option.strings.count
            case .integer:
                return option.integers.count
            case .double:
                return option.doubles.count
        }
    }

    /// Returns the specified option's list of values.
    public func getStringList(_ name: String) -> [String] {
        return getOption(name).strings
    }

    /// Returns the specified option's list of values.
    public func getIntList(_ name: String) -> [Int] {
        return getOption(name).integers
    }

    /// Returns the specified option's list of values.
    public func getDoubleList(_ name: String) -> [Double] {
        return getOption(name).doubles
    }


    // ---------------------------------------------------------------------
    // Commands.
    // ---------------------------------------------------------------------


    /// Register a command with its associated help text and callback
    /// function.
    public func newCmd(_ name: String, helptext: String, callback: @escaping (ArgParser) -> Void) -> ArgParser {
        let parser = ArgParser(helptext: helptext)
        parser.callback = callback
        parser.parent = self
        for alias in name.split(separator: " ") {
            commands[String(alias)] = parser
        }
        return parser
    }

    /// Returns true if the parser has found a command.
    public func hasCmd() -> Bool {
        return command != nil
    }

    /// Returns the command name, if the parser has found a command.
    public func getCmd() -> String? {
        return command
    }

    /// Returns the command parser instance, if the parser has found a command.
    public func getCmdParser() -> ArgParser? {
        if let name = command {
            return commands[name]
        }
        return nil
    }

    /// Returns a command parser's parent parser.
    public func getParent() -> ArgParser? {
        return parent
    }


    // ---------------------------------------------------------------------
    // Positional arguments.
    // ---------------------------------------------------------------------


    /// Returns true if the parser has found one or more positional arguments.
    public func hasArgs() -> Bool {
        return arguments.count > 0
    }

    /// Returns the number of positional arguments.
    public func numArgs() -> Int {
        return arguments.count
    }

    /// Returns the positional arguments as an array of strings.
    public func getArgs() -> [String] {
        return arguments
    }

    /// Attempts to parse and return the positional arguments as an array of
    /// integers. Exits with an error message on failure.
    public func getArgsAsInts() -> [Int] {
        var ints = [Int]()
        for arg in arguments {
            if let value = Int(arg) {
                ints.append(value)
            } else {
                exitError("cannot parse \(arg) as an integer")
            }
        }
        return ints
    }

    /// Attempts to parse and return the positional arguments as an array of
    /// doubles. Exits with an error message on failure.
    public func getArgsAsDoubles() -> [Double] {
        var doubles = [Double]()
        for arg in arguments {
            if let value = Double(arg) {
                doubles.append(value)
            } else {
                exitError("cannot parse \(arg) as a floating-point value")
            }
        }
        return doubles
    }


    // ---------------------------------------------------------------------
    // Parse arguments.
    // ---------------------------------------------------------------------


    /// Parse an array of string arguments. Defaults to parsing the
    /// application's command line arguments.
    public func parse(_ args: [String]? = nil) {
        let stream = ArgStream(args ?? Array(CommandLine.arguments[1...]))
        self.parseStream(stream)
    }

    /// Parse a stream of string arguments.
    private func parseStream(_ stream: ArgStream) {
        var parsing = true
        var is_first_arg = true

        // Loop while we have arguments to process.
        while stream.hasNext() {
            let arg = stream.next()

            // If parsing has been turned off, simply add the argument to the
            // array of positionals.
            if !parsing {
                arguments.append(arg)
            }

            // If we encounter a -- argument, turn off option parsing.
            else if arg == "--" {
                parsing = false
            }

            // Is the argument a long-form option?
            else if arg.starts(with: "--") {
                parseLongOption(String(arg.dropFirst(2)), stream)
            }

            // Is the argument a short-form option?
            else if arg.starts(with: "-") {
                if arg == "-" {
                    arguments.append(arg)
                } else if Array(arg)[1] >= "0" && Array(arg)[1] <= "9" {
                    arguments.append(arg)
                } else {
                    parseShortOption(String(arg.dropFirst(1)), stream)
                }
            }

            // Is the argument a registered command?
            else if is_first_arg, let cmdParser = commands[arg] {
                command = arg
                cmdParser.parseStream(stream)
                cmdParser.callback?(cmdParser)
            }

            // Is the argument the automatic 'help' command?
            else if is_first_arg && arg == "help" {
                if stream.hasNext() {
                    let name = stream.next()
                    if let cmdParser = commands[name] {
                        cmdParser.exitHelp()
                    } else {
                        exitError("'\(name)' is not a recognised command")
                    }
                } else {
                    exitError("the help command requires an argument")
                }
            }

            // Add the argument to our list of positionals.
            else {
                arguments.append(arg)
            }

            is_first_arg = false
        }
    }

    /// Parse a long-form option, i.e. an option beginning with a double dash.
    private func parseLongOption(_ arg: String, _ stream: ArgStream) {

        // Do we have an option of the form --name=value?
        if arg.contains("=") {
            parseEqualsOption(prefix: "--", arg: arg)
        }

        // Is the argument a registered option name?
        else if let option = options[arg] {
            option.found = true
            if option.type == OptionType.bool {
                option.bools.append(true)
            } else if stream.hasNext() {
                option.trySet(with: stream.next())
            } else {
                exitError("missing argument for --\(arg)")
            }
        }

        // Is the argument an automatic --help flag?
        else if arg == "help" && helptext != nil {
            exitHelp()
        }

        // Is the argument an automatic --version flag?
        else if arg == "version" && version != nil {
            exitVersion()
        }

        // The argument is not a recognised option name.
        else {
            exitError("--\(arg) is not a recognised option")
        }
    }

    /// Parse a short-form option, i.e. an option beginning with a single dash.
    private func parseShortOption(_ arg: String, _ stream: ArgStream) {

        // Do we have an option of the form -n=value?
        if arg.contains("=") {
            parseEqualsOption(prefix: "-", arg: arg)
            return
        }

        // We examine each character individually to support condensed options
        // with trailing arguments: -abc foo bar. If we don't recognise the
        // character as a registered option name, we check for an automatic
        // -h or -v flag before exiting.
        for char in arg {
            guard let option = options[String(char)] else {
                if char == "h" && helptext != nil {
                    exitHelp()
                } else if char == "v" && version != nil {
                    exitVersion()
                } else {
                    exitError("-\(char) is not a recognised option")
                }
            }
            option.found = true
            if option.type == OptionType.bool {
                option.bools.append(true)
            } else if stream.hasNext() {
                option.trySet(with: stream.next())
            } else {
                exitError("missing argument for -\(char)")
            }
        }
    }

    /// Parse an option of the form --name=value or -n=value.
    private func parseEqualsOption(prefix: String, arg: String) {
        let split = arg.split(
            separator: "=",
            maxSplits: 1,
            omittingEmptySubsequences: false
        )
        let name = String(split[0])
        let value = String(split[1])

        guard let option = options[name] else {
            exitError("\(prefix)\(name) is not a recognised option")
        }

        guard option.type != OptionType.bool else {
            exitError("invalid format for boolean flag \(prefix)\(name)")
        }

        guard value != "" else {
            exitError("missing argument for \(prefix)\(name)")
        }

        option.found = true
        option.trySet(with: value)
    }


    // ---------------------------------------------------------------------
    // Utility functions.
    // ---------------------------------------------------------------------


    /// Print the parser's help text and exit.
    public func exitHelp() -> Never {
        print(helptext ?? "")
        exit(0)
    }

    /// Print the parser's version string and exit.
    public func exitVersion() -> Never {
        print(version ?? "")
        exit(0)
    }

    /// Dump the parser's state to stdout.
    public func dump() {
        print("Options:")
        if options.count > 0 {
            for (name, opt) in options {
                switch opt.type {
                case .bool:
                    print("  \(name): (\(opt.fallbacks.bool)) \(opt.bools)")
                case .string:
                    print("  \(name): (\(opt.fallbacks.string)) \(opt.strings)")
                case .integer:
                    print("  \(name): (\(opt.fallbacks.int)) \(opt.integers)")
                case .double:
                    print("  \(name): (\(opt.fallbacks.double)) \(opt.doubles)")
                }
            }
        } else {
            print("  [none]")
        }

        print("\nArguments:")
        if arguments.count > 0 {
            for arg in arguments {
                print("  \(arg)")
            }
        } else {
            print("  [none]")
        }

        print("\nCommand:")
        print("  \(command ?? "[none]")")
    }
}
