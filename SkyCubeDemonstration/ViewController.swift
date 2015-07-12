//
//  ViewController.swift
//  SkyCubeDemonstration
//
//  Created by Simon Gladman on 11/07/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//

import UIKit
import SceneKit
import MetalKit

class ViewController: UIViewController
{
    let mainGroup = UIStackView()
    
    let sceneKitView = SCNView()
    let sceneKitScene = SCNScene()
    
    let turbiditySlider = SliderWidget(title: "Turbidity")
    let sunElevationSlider = SliderWidget(title: "Sun Elevation")
    let upperAtmosphereScatteringSlider = SliderWidget(title: "Upper Atmosphere Scattering")
    let groundAlbedoSlider = SliderWidget(title: "Ground Albedo")
    
    let material = SCNMaterial()
    
    let sky = MDLSkyCubeTexture(name: nil,
        channelEncoding: MDLTextureChannelEncoding.UInt8,
        textureDimensions: [Int32(160), Int32(160)],
        turbidity: 0,
        sunElevation: 0,
        upperAtmosphereScattering: 0,
        groundAlbedo: 0)
    
    let queue = dispatch_queue_create("TextureUpdateQueue", nil)
    var busy =  false // indicates MDLSkyCubeTexture is updating
    var changePending = false // indicates a pending user change
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.addSubview(mainGroup)
        mainGroup.axis = UILayoutConstraintAxis.Vertical
        
        mainGroup.addArrangedSubview(sceneKitView)

        mainGroup.addArrangedSubview(turbiditySlider)
        mainGroup.addArrangedSubview(sunElevationSlider)
        mainGroup.addArrangedSubview(upperAtmosphereScatteringSlider)
        mainGroup.addArrangedSubview(groundAlbedoSlider)
  
        turbiditySlider.value = 0.75
        sunElevationSlider.value = 0.5
        upperAtmosphereScatteringSlider.value = 0.15
        groundAlbedoSlider.value = 0.85
        
        turbiditySlider.addTarget(self, action: "sliderChangeHandler", forControlEvents: UIControlEvents.ValueChanged)
        sunElevationSlider.addTarget(self, action: "sliderChangeHandler", forControlEvents: UIControlEvents.ValueChanged)
        upperAtmosphereScatteringSlider.addTarget(self, action: "sliderChangeHandler", forControlEvents: UIControlEvents.ValueChanged)
        groundAlbedoSlider.addTarget(self, action: "sliderChangeHandler", forControlEvents: UIControlEvents.ValueChanged)
        
        sceneKitView.scene = sceneKitScene
        
        let camera = SCNCamera()
        
        camera.xFov = 45
        camera.yFov = 45
        
        let cameraNode = SCNNode()
        
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: -20)
        cameraNode.rotation = SCNVector4(x: 0, y: 1, z: 0, w: Float(M_PI))
        
        sceneKitScene.rootNode.addChildNode(cameraNode)
        
        sceneKitView.allowsCameraControl = true

        let torus = SCNTorus(ringRadius: 6, pipeRadius: 2)
        let torusNode = SCNNode(geometry: torus)
        torusNode.position = SCNVector3(x: 0, y: 0, z: 0)
        sceneKitScene.rootNode.addChildNode(torusNode)
        torusNode.runAction(SCNAction.repeatActionForever(SCNAction.rotateByX(1, y: 3, z: 5, duration: 3)))

        material.shininess = 0.15
        material.fresnelExponent = 0.25
        
        material.specular.contents = UIColor.whiteColor()
        material.diffuse.contents =  UIColor.darkGrayColor()
        material.reflective.contents = sky.imageFromTexture()?.takeUnretainedValue()
 
        torus.materials = [material]
        
        sceneKitScene.background.contents = sky.imageFromTexture()?.takeUnretainedValue()
        
        sliderChangeHandler()
    }

    func sliderChangeHandler()
    {
        guard !busy else
        {
            changePending = true
            return
        }
        
        busy = true

        dispatch_async(queue)
        {
            self.sky.turbidity = self.turbiditySlider.value
            self.sky.upperAtmosphereScattering = self.upperAtmosphereScatteringSlider.value
            self.sky.sunElevation = self.sunElevationSlider.value
            self.sky.groundAlbedo = self.groundAlbedoSlider.value
            
            self.sky.updateTexture()
            
            self.material.reflective.contents = self.sky.imageFromTexture()?.takeUnretainedValue()
            self.sceneKitScene.background.contents = self.sky.imageFromTexture()?.takeUnretainedValue()
            
            dispatch_async(dispatch_get_main_queue())
            {
                self.busy = false
                
                if self.changePending
                {
                    self.changePending = false
                    self.sliderChangeHandler()
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews()
    {
        let top = topLayoutGuide.length
        
        mainGroup.frame = CGRect(x: 0, y: top, width: view.frame.width, height: view.frame.height - top)
    }


}

