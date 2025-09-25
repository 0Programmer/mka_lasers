# mka-lasers refactored - mka_lasers
Create moving lasers in FiveM!

<img src="https://i.imgur.com/Yw9jcMR.png" alt="Example of lasers in bank vault" height="400px">

## Creation
Creating new lasers is simple. The `/lasers` command takes three possible sub-commands (start, end, save).

To start creating a new laser, use the command `/lasers start`. A green sphere will appear where you are looking in-game. This is the laser's "origin point" (where the laser will start). You can press E to select that point. You can have multiple origin points, which enables situations where you have a laser moving back and forth between multiple origin-target point pairs. To place more than one origin point just keep pressing E to add more points.

To switch to target point selection mode, press the X key, and the sphere will turn red. You can press E to place a point. Just like origin points, you can place as many target points as you want, however if you have multiple origin points, you must have the same number of target points. These points are the "targets" that your laser will point to. The laser can either follow these points in order, or randomly (only available if you have a single origin point), so make sure to place them in the order you want!

Once you are done selecting the target points, use `/lasers save` to save the created laser. You will be asked to input a name, and then the generated code for the newly created laser will be in the "lasers.txt" file in the resource's folder.

## Requirements
* [ox_lib](https://github.com/overextended/ox_lib/releases)
* [scully_emotemenu](https://github.com/Scullyy/scully_emotemenu) | Optional, used for crouch detection to check player dimensions.
* [Renewed-Weathersync](https://github.com/Renewed-Scripts/Renewed-Weathersync) | Optional, used to check the blackout state.

## How to Use
To use your newly created laser you can use the export.
```lua
local laser = exports.mka_lasers:createLaser(
    vector3(-173.14, 490.76, 137.32),
    { vector3(-169.32, 492.41, 137.41), vector3(-170.32, 494.02, 137.42) },
    {
        travelTimeBetweenTargets = {5.0, 5.0},
        waitTimeAtTargets = {1.3, 1.3},
        randomTargetSelection = true,
        name = 'optionalName01'
    }
)
```
After that call `laser.Activate()` on the `LaserWrapper` object to turn them on.
You can also call `laser.GetId()` to get the id and use it somewhere else.
```lua
local laser = exports.mka_lasers:getLaserById(1) -- OR exports.mka_lasers:getLaserByName('optionalName01')
if laser then
    laser.SetVisible(false)
    laser.Activate()
end
```

## Laser Options

| Property                 | Type    | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Default&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Required | Description                                                                                                                                                                                                                                                                  |
|--------------------------|---------|---------------------------------------------------------------------------------|----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| name                     | String  | ""                                                                              | false    | Name of the laser                                                                                                                                                                                                                                                            |
| travelTimeBetweenTargets | Table   | {1.0, 1.0}                                                                      | false    | The amount of time in seconds for the laser to travel from one target point to the next. This is a table of two values representing the minimum and maximum time, which is randomly selected between. If you don't want a random value, simply put the same number for both. |
| waitTimeAtTargets        | Table   | {0.0, 0.0}                                                                      | false    | The amount of time in seconds the laser will wait once it reaches a target point. This is a table of two values representing the minimum and maximum time, which is randomly selected between. If you don't want a random value, simply put the same number for both.        |
| randomTargetSelection    | Boolean | true                                                                            | false    | Whether the laser randomly selects the next target point. If this is false, the next point in the original order will be selected.                                                                                                                                           |
| maxDistance              | Float   | 20.0                                                                            | false    | Maximum distance of the laser.                                                                                                                                                                                                                                               |
| color                    | Table   | {255, 0, 0, 255}                                                                | false    | Color of the laser in rgba format (red, blue, green, alpha). This has to be a table of four integers representing each of the four colors in rgba.                                                                                                                           |

## onPlayerHit
onPlayerHit is a function on a laser which will call the given callback function anytime the laser goes from not hitting a player to hitting them, and vice-versa.
### Using onPlayerHit
```lua
laser.OnPlayerHit(function(playerBeingHit, hitPos)
    if playerBeingHit then
        -- Laser just hit the player
    else
        -- Laser just stopped hitting the player
        -- hitPos will just be a zero vector here
    end
end)

-- You can clear out onPlayerHit by just calling ClearOnPlayerHit()
laser.ClearOnPlayerHit()
```

## Other Laser Functions
Laser's have a few functions that can be useful for manipulating the laser after you create it. They are as follows:

- `laser.Activate()`             -- start the laser
- `laser.Deactivate()`           -- stop the laser
- `laser.Toggle()`               -- toggle active state
- `laser.GetActive()`            -- returns true/false
- `laser.GetVisible()`           -- returns true/false
- `laser.SetVisible(bool)`
- `laser.GetMoving()`            -- returns true/false
- `laser.SetMoving(bool)`
- `laser.SetColor(r,g,b,a)`
- `laser.GetColor()`             -- returns r,g,b,a
- `laser.Destroy()`              -- stops and removes from registry
- `laser.GetId()`                -- returns unique ID
- `laser.Raw()`                  -- returns raw Laser object
- `laser.SetOrigin(vector3(...))`
- `laser.SetTargets({vector3(...), vector3(...)})`
- `laser.SetTravelTimeBetweenTargets({min,max})`
- `laser.SetWaitTimeAtTargets({min,max})`
- `laser.SetRandomTargetSelection(bool)`
- `laser.SetExtensionEnabled(bool)`
- `laser.SetMaxDistance(number)`