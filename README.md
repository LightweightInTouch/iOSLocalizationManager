#iOSLocalizationManager
This is a simple tool that makes localization very lightweight and not so boring.

**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [iOSLocalizationManager](#ioslocalizationmanager)
	- [Requirements](#requirements)
	- [Features](#features)
		- [What is implemented?](#what-is-implemented)
		- [Options](#options)
		- [Easy localization](#easy-localization)
	- [Install](#install)
	- [Setup](#setup)
	- [Preferred Xcode project setup](#preferred-xcode-project-setup)
	- [Under the hood and what JSON says](#under-the-hood-and-what-json-says)
	- [Advanced setup](#advanced-setup)
		- [Podfile Gemfile Guardfile](#podfile-gemfile-guardfile)
			- [Content Examples](#content-examples)
			- [Automatic processes usage](#automatic-processes-usage)
	- [Further improvements](#further-improvements)
	- [Contact](#contact)
	- [License](#license)

##Requirements
Ruby 2.0 or later

##Features

- Automatic processes setup
- Swift and Objective-C support (see below examples)

###What is implemented?

- Swift and Objective-C convenient class generator
- Descriptive methods naming ( Objective-C style )

###Options
- `-w` - work directory option. It is used as output directory for localization .lproj and code-generated classes
- `-f` - localization file. It is used as seed for localization.
- `-p` - programming language. `Omit it for ObjectiveC` or use `s(wift)? for Swift`

Example: `ruby ios_localization_manage.rb -w new_directory/ -f specs/localization_file.json -p s`


###Easy localization
- Create a `localization.json` file
```json
{

	"hello" : {
		"world" : {
			"en" : "hello world",
			"fr" : "bonjour le monde"
		}
	},
	"general" : {
		"deleteButtonTitle" : {
			"en" : "delete",
			"fr" : "effacer"
		}
	},
	"padLockScreenLock" : {
		"titleLabelText" : {
			"en" : "title",
			"fr" : "titre"
		},
		"subtitleDefaultText" : {
			"en" : "default text",
			"fr" : "texte par défaut"
		},
		"subtitleAttemptsLeftPlural" : {
			"en" : "left",
			"fr" : ""
		},
		"subtitleAttemptsSingle" : {
			"en" : "left",
			"fr" : ""
		},
	}
}
```

- Compile localization file: `ruby ios_localization_manager.rb` and [see what happens](#under-the-hood-and-what-json-says)

- Use auto-generated `ILMStringsManager` methods in Swift:

```swift
	let helloWorld = ILMStringsManager.getHelloWorldString()
```

- Example setup for [ABPadLockScreen](https://github.com/abury/ABPadLockScreen)

```objective-c
    NSString *titleText = [ILMStringsManager getPadLockScreenLockTitleLabelTextString];    
    NSString *subtitleText = [ILMStringsManager getPadLockScreenLockSubtitleDefaultTextString];
    NSString *subtitleAttemptsLeftPluralText = [ILMStringsManager getPadLockScreenLockSubtitleAttemptsPluralString];
    NSString *subtitleAttemptsLeftSingleText = [ILMStringsManager getPadLockScreenLockSubtitleAttemptsSingleString];
    NSString *subtitleLockedOutText = [ILMStringsManager getPadLockScreenLockSubtitleLockedOutTextString];

    ABPadLockScreenViewController *controller = [[ABPadLockScreenViewController alloc] initWithDelegate:delegate complexPin:NO];
    [self setupLockScreenController:controller];
    
    [controller cancelButtonDisabled:YES];
    
    [controller setEnterPasscodeLabelText:titleText];
    [controller setSubtitleText:subtitleText];
    [controller setPluralAttemptsLeftText:subtitleAttemptsLeftPluralText];
    [controller setSingleAttemptLeftText:subtitleAttemptsLeftSingleText];
    [controller setLockedOutText:subtitleLockedOutText];
    [controller setDeleteButtonText:[ILMStringsManager getGeneralDeleteButtonTitleString]];
```

##Install

For now:

1. download project somewhere.
2. make a link to `ios_localization_manager.rb`
3. copy this link to destination directory with `localization.json`

##Setup
1. As you installed `iOSLocalizationManager` (see above Install section), you could start to use it.
2. Create file `localization.json` and put correct localization json into this file.
3. Once you are ready, you could run command `ruby ios_localization_manager.rb [options]` in your localization directory.
As a result you will see auto-generated (not-auto, but it could be done via `guard` tool) class with localization (`ILMStringsManager`)
4. Ta-da! You create your first localization!

##Preferred Xcode project setup
1. Create directory `Resources`
2. Create directory `Localization`
3. Put `ios_localization_manager.rb` link (You should not put original file!) into this directory.
4. Don't forget to exclude `ios_localization_manager.rb` link file FROM your project.
5. Put `localization.json` into directory `Localization`.
6. Don't forget to exclude `localization.json` file FROM your project.
7. After each script run you should check directories `#{lang}.lproj` for new localization tables and ADD them to your project.
8. Don't forget to INCLUDE new localization tables (.strings) files in `Localization` directory to your project
9. And, of course, ADD `ILMStringsManager` class (`h,m` or `swift`) to your project as convenient accessor to localization.

##Under the hood and what JSON says
Too complex setup, I know, but if you still here, I will explain auto-generation features and json structure.

First of all, I don't like localization, because it is annoying. 
You could forget to add strings to Localizable.strings file or so. Or you want to change localization somewhere, but you forget that you rename string and you have inconsistent localization as a result.

As a solution I would like to control localization process via compiler warnings as methods missing or so.

And here it comes. 

Script could create and auto-generate all needed methods for you!

But you should first understand localization process.

1. Any rooted node will used as prefix for new `.strings` file.
2. Any node could contain more nodes or could contain only one localization node.
3. Localization node could contain only one localization json object.
4. key path to localization node will be used as infix for method naming: `get` + {key_path} + `String`

Suppose that you have several controllers: FirstController and SecondController.
Suppose that each controller has several strings that you want localize.

- FirstController: one, three
- SecondController: two, four

You could create JSON as this one:

```json
{
	"firstAndSecond" : {
		"one" : {
			"en" : "one",
			"fr" : "un"
		},
		"two" : {
			"en" : "two",
			"fr" : "deux"
		},
		"three" : {
			"en" : "three",
			"fr" : "trois"
		},
		"four" : {
			"en" : "four",
			"fr" : "quatre"
		}
	}
}
```
or you could split controllers:

```json
{
	"first" : {
		"one" : {
			"en" : "one",
			"fr" : "un"
		},
		"three" : {
			"en" : "three",
			"fr" : "trois"
		}
	},
	"second" : {
		"two" : {
			"en" : "two",
			"fr" : "deux"
		},
		"four" : {
			"en" : "four",
			"fr" : "quatre"
		}
	}
}
```

As a result you will have a ILMSStringsManager class that will be shipped with these methods:

- controllers in one file
```swift
// Autogenerated by ruby localization script

class ILMStringsManager: NSObject {

	class func getStringFromTable(tableName: String, key: String) -> String {return NSLocalizedString(key, tableName: tableName, value:"", comment:"")}

	static var FirstLocalizationTable : String = "FirstLocalizationTable"

	class func getFirstAndSecondFourString() -> String {return getStringFromTable(FirstLocalizationTable,key:"first_ans_second_four")}
	class func getFirstAndSecondOneString() -> String {return getStringFromTable(FirstLocalizationTable,key:"first_ans_second_one")}
	class func getFirstAndSecondThreeString() -> String {return getStringFromTable(FirstLocalizationTable,key:"first_ans_second_three")}
	class func getFirstAndSecondTwoString() -> String {return getStringFromTable(FirstLocalizationTable,key:"first_ans_second_two")}
}
```

- controllers separated in different files

```
// Autogenerated by ruby localization script

class ILMStringsManager: NSObject {

	class func getStringFromTable(tableName: String, key: String) -> String {return NSLocalizedString(key, tableName: tableName, value:"", comment:"")}

	static var FirstLocalizationTable : String = "FirstLocalizationTable"
	static var SecondLocalizationTable : String = "SecondLocalizationTable"

	class func getFirstOneString() -> String {return getStringFromTable(FirstLocalizationTable,key:"first_one")}
	class func getFirstThreeString() -> String {return getStringFromTable(FirstLocalizationTable,key:"first_three")}
	class func getSecondFourString() -> String {return getStringFromTable(SecondLocalizationTable,key:"second_four")}
	class func getSecondTwoString() -> String {return getStringFromTable(SecondLocalizationTable,key:"second_two")}

}
```

Also, you have different .strings structure in these examples.

- controllers in one file

en.lproj/FirstAndSecondLocalizationTable.strings
fr.lproj/FirstAndSecondLocalizationTable.strings

- controllers separated in different files

en.lproj/FirstLocalizationTable.strings
en.lproj/SecondLocalizationTable.strings

fr.lproj/FirstLocalizationTable.strings
fr.lproj/SecondLocalizationTable.strings

##Advanced setup.

If you don't like localization, you could go further in automatic processes

### Podfile Gemfile Guardfile

You have project and you don't like 
- Pod manual install (`pod install`)
- Gem manual install (`bundle install`)
- ios_localization_manager manual invocation (`ruby ios_localization_manager.rb`)

You could use `guard` tool.

What you need first:
- Download `rvm` as ruby package manager or whatever you like.
- Install bundler ( I will explain automatic processes with it )
- And.. stop

You should add to project directory (where you place Podfile) several files:

- .ruby-version (rvm support file: it will contain ruby version)
- .ruby-gemset (rvm support file: it will contain ruby gemset)
- Gemfile (bundler support file: it will, heh, contain your gems for ruby for your xcode project)
- Podfile (you know)
- Guardfile (guard support file: it will contain guard instructions)

#### Content Examples
.ruby-version contents:
```
ruby-2.1.2
```

.ruby-gemset contents:
```
iOSDevelopment
```


Gemfile contents:

```
source 'https://rubygems.org'

gem 'guard'
gem 'guard-bundler'
gem 'terminal-notifier-guard', '~>1.6.1'
gem 'guard-shell'
gem 'cocoapods'
gem 'guard-cocoapods'
```

Guardfile contents:

```
# Actual gems here
guard :bundler do
  watch('Gemfile')
end

guard :cocoapods do
  watch('Podfile')
end

guard :shell do
  watch(%r{(?<path>^.+?)/localization.json}) do |m|
    if system("cd #{m[1]} && ruby ios_localization_manager.rb")
      n "#{m[0]} is correct", 'JSON Syntax', :success
    else
      n "#{m[0]} is incorrect", 'JSON Syntax', :failed
    end
  end
end
```

#### Automatic processes usage

1. open `Terminal.app`
2. `cd path_to_project/`
3. run `bundle install`
4. run `bundle exec guard`

That's all!
Now you have mister `Guard` that would do all work for you!

It will 
- install new pods (hit save for Podfile)
- install new gems into `{.ruby-version}@{.ruby-gemset}` (hit save for Gemfile)
- change localization (hit save for localization.json)

##Further improvements

I want to make this tool simple for usage, really!

Feel free for pull requests, issues, suggesstions, etc.

##Contact
Dmitry Lobanov http://github.com/lolgear

##License
iOSLocalizationManager is available under the MIT License.
See the [License](LICENSE) file for more info.
