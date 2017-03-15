À Propos
========

À Propos is a simple about controller to display links and informations about iOS application. This is actually used in my own projects: [Closer & Closer] (https://lisacintosh.com/closer/) and [iVerb](https://lisacintosh.com/iverb/).

Created in Objective-C for Xcode 8 and iOS 8 and later.

The code source is under public domain.

[Lisacintosh](https://lisacintosh.com/), 2017

![Screenshot](https://raw.githubusercontent.com/Lisapple/A-Propos/master/Example/Screenshot@2x.png)

Carthage
--------

[Carthage](https://github.com/Carthage/Carthage) was not designed to import isolated files to project but it can be useful to manage this kind of imported code.

* Create a `Cartfile` file with:

```
github "lisapple/a-propos"
```

* Run `carthage update` to get last version of À Propos.

* Manually import classes form `Carthage/Checkouts/a-propos/Classes` into Xcode project (do not copy files if you want to update them from this repository later).
