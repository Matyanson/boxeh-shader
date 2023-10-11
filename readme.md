# Boxeh shaders

## Name
My initial motivation to create this shader was to implement DOF using the classic **Box** blur. Box blur is easy to implement, really fast and has a square kernel.<br>
When DOF is pressent, lights in the distance look like bubbles. This artifact is called "**Bokeh**". Since Box blur uses a square kernel, the Bokeh is in the shape of square. Which fits minecraft blocky nature very well.

Shortly: **Bokeh** + **Box** blur = **Boxeh**

## Goals

### 1. Efficiency

Choose only effects that have big impact on visualls but have low computing cost.

### 2. Realism

- reality dictates the value of each constant, no artistic input.
- technique should maximize realism without sacrificing efficiency.
- Limit effects to those observable by the human eye

For example the DOF effect uses focal length that matches the average human eye lens (~17mm). Or The Lens flare effect is not implemented since it is visible by camera lens only.

### 3. Customizability

![Settings menu](images/settings.png)
Each effect can be turned on/off. For instance,this shader can be used to enhance water only. When all effects are disabled, the visuals and performance should resemble vanilla Minecraft. 

## Features

### Custom lighting

 | Vanilla  | Boxeh |
 | ------------- | ------------- |
 | ![](images/lighting_vanilla.png) | ![](images/lighting_boxeh.png) |
 | ![Cave lighting vanilla](images/torch_in_cave_vanilla.png) | ![Cave lighting Boxeh](images/torch_in_cave_boxeh.png) |

### Shadows

![Shadows](images/shadows_boxeh.png)

### Atmospheric Fog

![Atmospheric Fog](images/atmospheric_fog_boxeh.png)

### Reflection

![Reflection](images/reflection.png)

### Water texture opacity

![Water texture opacity](images/water_texture_opacity.png)

### Water Light Absorption (color)

![Water light absorption](images/water_color.png)

### Water surface waves

![Water waves](images/water_waves.png)

### Water Light Refraction

![Refraction](images/water_refraction.png)
![Refraction gif](images/water_refraction.gif)
This effect is NOT faked. That is why you can see an artifact near the bottom edge of the screen. The shader can't draw what is not visible.

### Godrays (Sun lightrays)

![Godrays](images/godrays_above_water.png)

### Depth Of Field Blur

![DOF](images/dof_on_water.png)


## Album
![Godray sunset](images/dof_godray_sunset_2.png)
![Godray sunset](images/dof_godray_sunset.png)
![Moon reflection](images/moon_reflection.png)
![Pufferfish in water](images/pufferfish_in_water.png)
![Lamas](images/lamas_in_water.png)
![Godray trough tree branches](images/example.png)