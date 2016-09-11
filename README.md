PhrozenByte Stunt Drag Markers 2.0
==================================

PhrozenByte Stunt Drag Markers is a resource for Multi Theft Auto: San Andreas (MTA:SA), allowing mappers to add scripted events to their maps.

Please note that this resource requires [PhrozenByte Debug][PhrozenByteDebug] to be installed. This resource was primarly developed for MTA's Race gamemode, but should, at least basically, work with any other gamemode. Code contributions implementing support for other gamemodes are highly appreciated. We're looking forward to any contribution!

The resource fully supports MTA's official map editor by allowing mappers to freely place Stunt Drag Markers (SDMs) in their maps. Everything is very easy to use and doesn't require any deeper knowledge of the technology behind. Simply…

1. download the resource files,
2. move them to a new `stunt-drag-markers` folder in your local resources directory (`server/mods/deathmatch/resources/`),
3. click on the *Definitions* icon in MTA's map editor and add *PhrozenByte Stunt Drag Markers* to your map,
4. scroll your mousewheel on the buttons in the bottom-left corner until you reach the Stunt Drag Marker buttons, and
5. place Stunt Drag Markers in your map.

After you've created your map, upload the map resource, the `stunt-drag-markers` resource and the [`phrozenbyte-debug` resource][PhrozenByteDebug] to your server and move them to MTA's resource directory. That's it!

PhrozenByte Stunt Drag Markers currently supports the following markers:

* `sdmText`: Creates a custom text on the player's screen when he hits the marker.
* `sdmMagnet`: Turns the vehicle's wheels into an magnet, i.e. allows a player to drive a vehicle on walls and even the ceiling.
* `sdmGravity`: Changes a vehicle's gravity.
* `sdmTeleport`: Teleports a player's vehicle to the position of the matching `sdmTeleportTarget` marker.
* `sdmHealth`: Changes the health of a player's vehicle. You can repair it, make it burn or blow it up, depending on the health you set.
* `sdmSky`: Changes the sky color for an player.
* `sdmWater`: Changes the water color for an player.

It additionally adds the following map settings:

* `skyTopColor` and `skyBottomColor`: Changes the sky color for all players.
* `waterColor`: Changes the water color for all players.
* `gravity`: Changes the gravity on the server.

When you're experiencing problems with PhrozenByte Stunt Drag Markers, please don't hesitate to create a new [Issue][] on GitHub. If you're a developer, you can help make PhrozenByte Stunt Drag Markers better by contributing code; simply open a new [PR][] on GitHub. Contributing to PhrozenByte Stunt Drag Markers is highly appreciated! 

License tl;dr
-------------

PhrozenByte Stunt Drag Markers is free software, released under the terms of the GNU Affero General Public License version 3 (GNU AGPL).

According to that you **can**...

- modify the software and create derivatives
- distribute the original or modified (derivative) works
- use the software for both private and commercial purposes

However, you **cannot**...

- sublicense the software, i.e. any user has the right to run, modify and distribute the work
- hold the software/license owner liable for damages (i.e. no warranty)

No matter what, you **must**...

- retain the original copyright and include the full license text
- state (non-trivial) changes made to the software and disclose your source code when distributing, publishing or serving a modified/derivative software

Put briefly, the GNU AGPL is virtually the same as the GNU GPL: a free software license with copyleft. However, there's a **important difference**: Serving the software is considered as distribution (the so-called "ASP loophole")!

This means that if you modify the software, you **must** allow any player connected to your MTA server to retrieve the source code of your modified/derivative version of PhrozenByte Stunt Drag Markers (e.g. by providing download links). To make things easier, we have included a `DOWNLOAD.md` file which is declared as client-side file in the `meta.xml`. If you modify the software, you can comply with the condition by changing the download URL in this file.

To cut a long story short: We recommend you to fork our GitHub repository and push all changes you've made to your fork ([Learn more][HelpForking]). Change the URL in the `DOWNLOAD.md` to your forked GitHub repository and you're ready to go. We would love to see if you open a PR to let your improvements flow back into the upstream project - this is called *Contributing* ([Learn more][HelpContributing]).

PhrozenByte Stunt Drag Markers furthermore adds the `/license` command returning the original copyright and declares the `LICENSE` file as client-side file in the `meta.xml`. This also serves the above license terms.

For the avoidance of doubt: Although the GNU AGPL is a copyleft license, you are *not* required to publish MTA gamemodes or maps using PhrozenByte Stunt Drag Markers under the terms of the GNU AGPL. *Using* this resource does *not* "infect" your gamemodes and maps, they do *not* become derivative works.

<small>Please note that this is a human-readable summary of the [full license][License].</small>

Copyright
---------

Copyright (C) 2015-2016  Daniel Rudolf <http://www.daniel-rudolf.de/>

This program is free software: you can redistribute it and/or modify it under the terms of the [GNU Affero General Public License][License] as published by the Free Software Foundation, version 3 of the License only.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Affero General Public License for more details. You should have received a copy of the [GNU Affero General Public License][LicenseOnline] along with this program.

[PhrozenByteDebug]: https://github.com/PhrozenByte/mtasa-debug
[Issue]: https://github.com/PhrozenByte/stunt-drag-markers/issues
[PR]: https://github.com/PhrozenByte/stunt-drag-markers/pulls
[HelpForking]: https://guides.github.com/activities/forking/
[HelpContributing]: https://guides.github.com/activities/contributing-to-open-source/
[License]: LICENSE
[LicenseOnline]: http://www.gnu.org/licenses/
