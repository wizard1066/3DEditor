//
//  ContentView.swift
//  Molecule
//
//  Created by localuser on 10.10.22.
//

import SwiftUI
import SceneKit
import Combine

var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
let toggle = PassthroughSubject<Bool,Never>()
let mutate = PassthroughSubject<Void,Never>()
let undoer = PassthroughSubject<Void,Never>()
let zoomer = PassthroughSubject<Bool,Never>()
let spin90yp = PassthroughSubject<Void,Never>()
let spin90yn = PassthroughSubject<Void,Never>()
let spin90xp = PassthroughSubject<Void,Never>()
let spin90xn = PassthroughSubject<Void,Never>()
let spin90zp = PassthroughSubject<Void,Never>()
let spin90zn = PassthroughSubject<Void,Never>()

let update = PassthroughSubject<String,Never>()
let drag = PassthroughSubject<CGPoint,Never>()


var change:AnyCancellable!
var mode:AnyCancellable!
var undone: AnyCancellable!
var zoom: AnyCancellable!
var rotate90yp: AnyCancellable!
var rotate90yn: AnyCancellable!
var rotate90xp: AnyCancellable!
var rotate90xn: AnyCancellable!
var rotate90zp: AnyCancellable!
var rotate90zn: AnyCancellable!
var updating: AnyCancellable!
var dragging: AnyCancellable!

let screenSize: CGRect = UIScreen.main.bounds
let screenWidth: CGFloat = UIScreen.main.bounds.width - 128
let screenHeight: CGFloat = UIScreen.main.bounds.height - 128
let snakeSize:CGFloat = 0.2

var nodes:[NewNode] = []

enum Directions:Int {
    case north = 0
    case south = 1
    case east = 2
    case west = 3
    case up = 4
    case down = 5
}

struct Fonts {
    static func avenirNextCondensedBold (size: CGFloat) -> Font {
        return Font.custom("AvenirNextCondensed-Bold", size: size)
    }
}

struct ContentView: View {
    

    @State var snakeHead = SCNVector3(x: 0, y: 0, z: 0)
    @State var snakeStart = 0
    

    @State var snakeCount = 0
    
    @State var pause = true
    @State var deadEnd:[SCNVector3] = []
    @State var scene = SCNScene()
    @State var panner = true
    @State var debug = ""
    @State var dragDistance:CGFloat = 1
    @State var action = "Push"
    @State var actioned = false
    
    var body: some View {
        ZStack {
            VStack {
//                Text("\(debug)")
//                    .font(.largeTitle)
//                    .padding()
//                    .onReceive(update) { value in
//                        debug = value
//                    }
                SceneView(
                    scene: scene, options: []
                )
                .border(Color.black, width: 3)
                
                .gesture(
                    DragGesture(minimumDistance: dragDistance)
                        .onChanged { gesture in
                            drag.send(gesture.location)
                        }
                )
            }
            if !panner {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundColor(Color(UIColor.green))
                    .frame(width: 256, height: 256)
            }
            VStack {
                Spacer()
                HStack {
//                    Text(action)
//                        .font(Fonts.avenirNextCondensedBold(size: 20))
//                        .onTapGesture {
//                           action = action == "Push" ? "Pull" : "Push"
//                        }
//                        .padding()
                    Text("ZoomOut")
                        .font(Fonts.avenirNextCondensedBold(size: 20))
                        .onTapGesture {
                            zoomer.send(false)
                        }.padding()
                    Text("ZoomIn")
                        .font(Fonts.avenirNextCondensedBold(size: 20))
                        .onTapGesture {
                            zoomer.send(true)
                        }.padding()
                    
                    Text("Mode")
                    //Image(systemName: "circle.dashed")
                        .font(Fonts.avenirNextCondensedBold(size: 20))
                        .frame(height: .minimum(12, 12))
                        .onTapGesture {
                            panner.toggle()
                            dragDistance = CGFloat(dragDistance != 1 ? 1:24)
                            print("dD \(dragDistance)")
                        }.padding()
                        .background(panner ? .blue:.clear)
                        .foregroundColor(panner ? .white:.black)
                        
                    Text("Mutate")
                        .font(Fonts.avenirNextCondensedBold(size: 20))
                        .onTapGesture {
                            mutate.send()
                        }.padding()
                    Group {
//                        Text("Spinyp")
//                            .font(Fonts.avenirNextCondensedBold(size: 20))
//                            .onTapGesture {
//                                spin90yp.send()
//                            }.padding()
//                        Text("Spinyn")
//                            .font(Fonts.avenirNextCondensedBold(size: 20))
//                            .onTapGesture {
//                                spin90yn.send()
//                            }.padding()
//                        Text("Spinxp")
//                            .font(Fonts.avenirNextCondensedBold(size: 20))
//                            .onTapGesture {
//                                spin90xp.send()
//                            }.padding()
//                        Text("Spinxn")
//                            .font(Fonts.avenirNextCondensedBold(size: 20))
//                            .onTapGesture {
//                                spin90xn.send()
//                            }.padding()
//                        Text("Spinzp")
//                            .font(Fonts.avenirNextCondensedBold(size: 20))
//                            .onTapGesture {
//                                spin90zp.send()
//                            }.padding()
//                        Text("Spinzp")
//                            .font(Fonts.avenirNextCondensedBold(size: 20))
//                            .onTapGesture {
//                                spin90zn.send()
//                            }.padding()
                    }
                }
            }
        }
    }
}



struct SceneView: UIViewRepresentable {
    
    var scene: SCNScene
    var options: [Any]
    
    var view = SCNView()
    var coreNode = SCNNode()
    var cameraNode = SCNNode()
    
    
    func makeUIView(context: Context) -> SCNView {
        
        
        
        view.scene = scene
        //view.pointOfView = scene.rootNode.childNode(withName: "cameraNode", recursively: true)
        view.allowsCameraControl = true
        view.autoenablesDefaultLighting = false
        
        let camera = SCNCamera()
        camera.fieldOfView = 90.0
        camera.orthographicScale = 9
        camera.zNear = 0
        camera.zFar = 1000
        let light = SCNLight()
        light.color = UIColor.white
        light.type = .directional

        cameraNode.simdPosition = SIMD3<Float>(0.0, 0.0, 8.0)
        cameraNode.camera = camera
        cameraNode.name = "cameraNode"
        
        view.pointOfView = cameraNode
        
        
                           
        coreNode.name = "coreNode"
        scene.rootNode.addChildNode(coreNode)
        return view
    }
    
    func updateUIView(_ view: SCNView, context: Context) {
      
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(view)
    }
    
    
}


    
    
class Coordinator: NSObject {
    private let view: SCNView
    private var coreNode: SCNNode!
    private var player = false
    private var snakeHead = SCNVector3(x:0,y:0,z:0)
    private var snakeGrid:[Int:SCNVector3] = [:]
    private var snakeParts:[SCNNode] = []
    private var deadEnd:[SCNVector3] = []
    private var paused = true
    private var count = 0
    private var name = 0
    private var dragged = CGPoint.zero
    
    private var isMoving = false
    private var preNode:NewNode! {
        didSet {
          //  print("fuck")
        }
    }
    
    init(_ view: SCNView) {
        self.view = view
        super.init()
        
        let longRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longTap(_:)))
        view.addGestureRecognizer(longRecognizer)

//        let tripRecognizer = UITapGestureRecognizer(target: self, action: #selector(tripTap(_:)))
//        tripRecognizer.numberOfTapsRequired = 3
//        view.addGestureRecognizer(tripRecognizer)
        
        let doubleRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        doubleRecognizer.numberOfTapsRequired = 2
        //doubleRecognizer.require(toFail: tripRecognizer)
        view.addGestureRecognizer(doubleRecognizer)
       
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapRecognizer.require(toFail: doubleRecognizer)
        view.addGestureRecognizer(tapRecognizer)

    //    let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    //    view.addGestureRecognizer(panRecognizer)
        
        //let newNode = moleculeBody(snakePosition: SCNVector3(x: 0, y: 0, z: 0))
        //self.view.scene?.rootNode.addChildNode(newNode)
        
        dragging = drag.sink(receiveValue: { [self] points in
            let hitResults = view.hitTest(points, options: [:])
            if hitResults.count > 0 {
                let result = hitResults[hitResults.count - 1].node as? NewNode
                let newPosition = points.scnVector3Value(view: view, depth: Float(result!.position.z))
                reassignNode(newNode: result!, newPosition: newPosition)
            }
        })
        
        updating = timer.sink(receiveValue: { [self] choosen in
            // worldPosition 7.9
            let foo = view.pointOfView!.worldPosition
            update.send("\(foo)")
        })
        
        rotate90yn = spin90yn.sink(receiveValue: { [self] choosen in
            let quaternion = simd_quatf(angle: GLKMathDegreesToRadians(90), axis: simd_float3(0,1,0))
            //coreNode.simdOrientation = quaternion * coreNode.simdOrientation
            view.pointOfView!.simdOrientation = quaternion * view.pointOfView!.simdOrientation
         //   print("view.pointOfView?.simdPosition \(view.pointOfView?.simdPosition)")
        //    view.pointOfView?.simdPosition = SIMD3(x: 16, y: 0, z: 2)
            print("view.pointOfView?.simdPosition YN\(view.pointOfView?.simdPosition)")
        })
        
        rotate90yp = spin90yp.sink(receiveValue: { [self] choosen in
            let quaternion = simd_quatf(angle: GLKMathDegreesToRadians(-6), axis: simd_float3(0,1,0))
            //coreNode.simdOrientation = quaternion * coreNode.simdOrientation
     //       view.pointOfView!.simdOrientation = quaternion * view.pointOfView!.simdOrientation
            print("view.pointOfView?.simdPosition YP\(view.pointOfView?.simdPosition)")
        })
        rotate90xn = spin90xn.sink(receiveValue: { [self] choosen in
            let quaternion = simd_quatf(angle: GLKMathDegreesToRadians(90), axis: simd_float3(1,0,0))
         //   coreNode.simdOrientation = quaternion * coreNode.simdOrientation
            view.pointOfView!.simdOrientation = quaternion * view.pointOfView!.simdOrientation
        })
        
        rotate90xp = spin90xp.sink(receiveValue: { [self] choosen in
            let quaternion = simd_quatf(angle: GLKMathDegreesToRadians(-90), axis: simd_float3(1,0,0))
        //    coreNode.simdOrientation = quaternion * coreNode.simdOrientation
            view.pointOfView!.simdOrientation = quaternion * view.pointOfView!.simdOrientation
        })
        rotate90zn = spin90zn.sink(receiveValue: { [self] choosen in
            let quaternion = simd_quatf(angle: GLKMathDegreesToRadians(90), axis: simd_float3(0,0,1))
        //    coreNode.simdOrientation = quaternion * coreNode.simdOrientation
            view.pointOfView!.simdOrientation = quaternion * view.pointOfView!.simdOrientation
        })
        
        rotate90zp = spin90zp.sink(receiveValue: { [self] choosen in
            let quaternion = simd_quatf(angle: GLKMathDegreesToRadians(-90), axis: simd_float3(0,0,1))
        //    coreNode.simdOrientation = quaternion * coreNode.simdOrientation
            view.pointOfView!.simdOrientation = quaternion * view.pointOfView!.simdOrientation
        })
        
        zoom = zoomer.sink(receiveValue: { [self] direction in
            var result = self.view.pointOfView
            if !direction {
                if view.pointOfView!.worldPosition.x > 3.5 {
                    result!.position.x += 1
                }
                if view.pointOfView!.worldPosition.x < -3.5 {
                    result!.position.x -= 1
                }
                if view.pointOfView!.worldPosition.y > 3.5 {
                    result!.position.y += 1
                }
                if view.pointOfView!.worldPosition.y < -3.5 {
                    result!.position.y -= 1
                }
                if view.pointOfView!.worldPosition.z > 3.5 {
                    result!.position.z += 1
                }
                if view.pointOfView!.worldPosition.z < -3.5 {
                    result!.position.z -= 1
                }
            } else {
                if view.pointOfView!.worldPosition.x > 3.5 {
                    result!.position.x -= 1
                }
                if view.pointOfView!.worldPosition.x < -3.5 {
                    result!.position.x += 1
                }
                if view.pointOfView!.worldPosition.y > 3.5 {
                    result!.position.y -= 1
                }
                if view.pointOfView!.worldPosition.y < -3.5 {
                    result!.position.y += 1
                }
                if view.pointOfView!.worldPosition.z > 3.5 {
                    result!.position.z -= 1
                }
                if view.pointOfView!.worldPosition.z < -3.5 {
                    result!.position.z += 1
                }
            }
        })
        
        undone = undoer.sink(receiveValue: { [self] choosen in
            print("undo \(preNode)")
            reassignNode(newNode: preNode, newPosition: preNode.position)
            
        })
        
        mode = toggle.sink(receiveValue: { [self] choosen in
            if choosen {
             //   view.removeGestureRecognizer(panRecognizer)
            } else {
         //       view.addGestureRecognizer(panRecognizer)
            }
        })
        
        change = mutate.sink(receiveValue: { [self] choosen in
            
            var cells2Delete:[UUID] = []
            var cellBoxes:[SCNVector3] = []
            if nodes.count > 0 {
                let baseCell = nodes.first
                for i in stride(from: (baseCell?.position.x)! - 8, through: (baseCell?.position.x)! + 8, by: 1) {
                    for k in stride(from: (baseCell?.position.y)! - 8, through: (baseCell?.position.y)! + 8, by: 1) {
                        for r in stride(from: (baseCell?.position.z)! - 8, through: (baseCell?.position.z)! + 8, by: 1) {
                            let newPosition = SCNVector3(x: i, y: k, z: r)
                            cellBoxes.append(newPosition)
                        }
                    }
                }
            }
            
            let nodeCopy = nodes.copiedElements().dropFirst()
            if nodes.count > 1 {
                
                for nodeA in nodes {
                    var count = 0
                    for nodeB in nodeCopy {
                        let nodeOfI = nodeA
                        if inside(point: nodeB.position, center: nodeA.position, radius: 1.1) {
                            count += 1
                        }
                    }
                    // Cell with more than 4 neighbours dies
                    if count > 4 {
                        nodeA.removeFromParentNode()
                        cells2Delete.append(nodeA.uid)
                    }
                    // Cell with less than 2 neighbours dies
                    if count < 5 {
                        nodeA.removeFromParentNode()
                        cells2Delete.append(nodeA.uid)
                    }
                }
            }
            
            for nodeA in cellBoxes {
                var count2 = 0
                for nodeB in nodes {
                    if inside(point: nodeB.position, center: nodeA, radius: 1.1) {
                        count2 += 1
                    }
                }
                
                if count2 == 4 {
                    let newPart = moleculeBody(snakePosition: nodeA, name: String("Node \(name)"))
                    self.view.scene?.rootNode.addChildNode(newPart)
                    nodes.append(newPart as! NewNode)
                    
                }
            }
            
            // cleanup
            
            for uid in cells2Delete {
                deleteNode(nodeID: uid)
                //let indexOf = nodes.firstIndex { (node) -> Bool in
                  //  node.uid == uid
                //}
                //nodes.remove(at: indexOf!)
                // delete cell with UUID from nodes Struct
            }
            
        })
        
    }
    
    func intersects(point:SCNVector3, center:SCNVector3, radius:Float) -> Bool
    {
        let displacementToCenter = point - center;
        let radiusSqr = radius * radius;
        let intersects = displacementToCenter.magnitude < radiusSqr;
        return intersects;
    }
    
    func inside(point:SCNVector3, center:SCNVector3, radius:Float ) -> Bool {
        let x1 = pow((center.x - point.x), 2)
        let y1 = pow((center.y - point.y), 2)
        let z1 = pow((center.z - point.z), 2)
        let sum = x1 + y1 + z1
        if Int(sum) < Int(radius) ^ Int(2.0) {
            return true
        } else {
            return false
        }
    }
    
    func CGPointToSCNVector3(view: SCNView, depth: Float, point: CGPoint) -> SCNVector3 {
        let projectedOrigin = view.projectPoint(SCNVector3Make(0, 0, depth))
        let locationWithz   = SCNVector3Make(Float(point.x), Float(point.y), projectedOrigin.z)
        return view.unprojectPoint(locationWithz)
    }
    
    func deleteNode(nodeID: UUID) {
        let indexOf = nodes.firstIndex { (node) -> Bool in
            node.uid == nodeID
        }
        if indexOf != nil {
            // delete cell with UUID from nodes Struct Array
            nodes.remove(at: indexOf!)
        } else {
            assert(false,"NeverHappens")
        }
        
    }
    
    func reassignNode(newNode: NewNode, newPosition:SCNVector3) {
        let indexOf = nodes.firstIndex { (node) -> Bool in
            node.uid == newNode.uid
        }
        if indexOf != nil {
            newNode.position = newPosition
            nodes[indexOf!] = newNode
        } else {
            assert(false,"NeverHappens")
        }
    }
    
    @objc func handlePan(_ gestureRecognize: UIPanGestureRecognizer) {
        let p = gestureRecognize.location(in: view)
        let hitResults = view.hitTest(p, options: [:])
        
        if hitResults.count > 0 {
            let result = hitResults[hitResults.count - 1].node as? NewNode
            let newPosition = p.scnVector3Value(view: view, depth: Float(result!.position.z))
            
//                view.scene?.rootNode.enumerateChildNodes { (node, stop) in
//                    print("node \(node.name)")
//                    if node.name == "coreNode" {
//                        coreNode = node
//                    }
//                }
            reassignNode(newNode: result!, newPosition: newPosition)
        }
    }
    
    @objc func longTap(_ gestureRecognize: UIGestureRecognizer) {
        let p = gestureRecognize.location(in: view)
        let hitResults = view.hitTest(p, options: [:])
        
        if hitResults.count > 0 {
            let result = hitResults[0].node as? NewNode
            if gestureRecognize.state == .ended {
               deleteNode(nodeID: result!.uid)
               result?.removeFromParentNode()
                
                view.scene?.rootNode.enumerateChildNodes { (node, stop) in
                   
                    if node.name == "coreNode" {
                        coreNode = node
                    }
                }
                
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 4
                SCNTransaction.commit()
                
            }
        }
    }
    
//    @objc func tripTap(_ gestureRecognize: UIGestureRecognizer) {
//        return
//        let p = gestureRecognize.location(in: view)
//        let hitResults = view.hitTest(p, options: [:])
//
//        if hitResults.count > 0 {
//            let result = hitResults[0].node as? NewNode
//            preNode = result!
//            let newZ = (result?.position.z.rounded(FloatingPointRoundingRule.toNearestOrEven))! - 1
//            let newX = (result?.position.x.rounded(FloatingPointRoundingRule.toNearestOrEven))!
//            let newY = (result?.position.y.rounded(FloatingPointRoundingRule.toNearestOrEven))!
//            let newPosition = SCNVector3(x: newX, y: newY, z: newZ)
//            result?.position = newPosition
//            print("trip position \(hitResults.count) \(newPosition)")
//            reassignNode(newNode: result!, newPosition: newPosition)
//            print("newNode ",result!.worldFront)
//        }
//    }
    
    @objc func doubleTap(_ gestureRecognize: UIGestureRecognizer) {
        let p = gestureRecognize.location(in: view)
        let hitResults = view.hitTest(p, options: [:])
        
        if hitResults.count > 0 {
            var result = hitResults[0].node as? NewNode
            
            if view.pointOfView!.worldPosition.x > 3.5 {
                result!.position.x += 1
            }
            if view.pointOfView!.worldPosition.x < -3.5 {
                result!.position.x -= 1
            }
            if view.pointOfView!.worldPosition.y > 3.5 {
                result!.position.y += 1
            }
            if view.pointOfView!.worldPosition.y < -3.5 {
                result!.position.y -= 1
            }
            if view.pointOfView!.worldPosition.z > 3.5 {
                result!.position.z += 1
            }
            if view.pointOfView!.worldPosition.z < -3.5 {
                result!.position.z -= 1
            }
            
            reassignNode(newNode: result!, newPosition: result!.position)
            print("newNode ",result!.worldOrientation)
        }
    }
    
    @objc func handleTap(_ gestureRecognize: UIGestureRecognizer) {
            let p = gestureRecognize.location(in: view)
            let hitResults = view.hitTest(p, options: [:])
            
        
            if hitResults.count == 0 {
                var newPosition = p.scnVector3Value(view: view, depth: 0)
                if gestureRecognize.state == .ended {
                    newPosition.x = newPosition.x.rounded(FloatingPointRoundingRule.toNearestOrEven)
                    newPosition.y = newPosition.y.rounded(FloatingPointRoundingRule.toNearestOrEven)
                    newPosition.z = newPosition.z.rounded(FloatingPointRoundingRule.toNearestOrEven)
                    
                    let newPart = moleculeBody(snakePosition: newPosition, name: String("Node \(name)"))
                    name += 1
                    view.scene?.rootNode.enumerateChildNodes { (node, stop) in
                        print("node \(node.name)")
                        if node.name == "coreNode" {
                            coreNode = node
                        }
                    }
                    
                    self.coreNode.addChildNode(newPart)
                    nodes.append(newPart as! NewNode)
                    print("hitResultsZero \(newPosition) ")
                    
                    
                }
            }

            if hitResults.count > 0 {
                print("hitResults \(hitResults.count)")
                let result = hitResults[0].node.copy() as? NewNode
                // newPosition2 total shit
                var newPosition = p.scnVector3Value(view: view, depth: result!.position.z)
                var copied = result
                
                print("hitResults \(result!.name) \(result!.position) ")
                var loop = 0
                
                // result!.position needs to be updated to next node!!
                while (intersects(point: newPosition, center: result!.position, radius: 0.5)) {
                    if view.pointOfView!.worldPosition.x > 3.5 {
                        result!.position.x += 1
                    }
                    if view.pointOfView!.worldPosition.x < -3.5 {
                        result!.position.x -= 1
                    }
                    if view.pointOfView!.worldPosition.y > 3.5 {
                        result!.position.y += 1
                    }
                    if view.pointOfView!.worldPosition.y < -3.5 {
                        result!.position.y -= 1
                    }
                    if view.pointOfView!.worldPosition.z > 3.5 {
                        result!.position.z += 1
                    }
                    if view.pointOfView!.worldPosition.z < -3.5 {
                        result!.position.z -= 1
                    }
                    loop += 1
                }
                let newPart = moleculeBody(snakePosition: result!.position, name: String("Node \(name)"))
                name += 1
                self.coreNode.addChildNode(newPart)
                nodes.append(newPart as! NewNode)
                
            }
        }
    
    func returnPath(poi: SCNVector3) {
        for node in nodes {
            if inside(point: poi, center: node.position, radius: 0.4) {
                //print("-------------> node \(node.name)")
                //let de = debugNode(gridPosition: node.position)
                //coreNode.addChildNode(de)
            }
            var nodeY = node.position
            nodeY.y += 1
            var nodeX = node.position
            nodeX.x += 1
            var nodeZ = node.position
            nodeZ.z += 1
            if intersects(point: poi, center: nodeZ, radius: 0.5) {
                print("-------------> node \(node.name)")
               // let de = debugNode(gridPosition: nodeZ)
               // coreNode.addChildNode(de)
            }
        }
    }
    
    func moleculeBody(snakePosition:SCNVector3, name:String) -> SCNNode {
        let nextGeometry = SCNSphere(radius: 0.5)
        let rnd = Float.random(in: 0...1)
        let nextColor = UIColor(hue: CGFloat(rnd), saturation: 1, brightness: 1, alpha: 0.8)
        nextGeometry.firstMaterial?.diffuse.contents = nextColor
        nextGeometry.segmentCount = 6
        let nextIndex = SIMD3(x: Int(snakePosition.x), y: Int(snakePosition.y), z: Int(snakePosition.z))
        let nextNode = NewNode(proxy: nextIndex, geometry: nextGeometry, color: nextColor)
        nextNode.position = snakePosition
        nextNode.name = name
        //print("nextNode \(nextNode.uid)")
        nodes.append(nextNode)
        return nextNode
    }
    
    func gridBody(gridPosition:SCNVector3) -> SCNNode {
        let nextGeometry = SCNSphere(radius: 0.1)
        //let rnd = Float.random(in: 0...1)
        //let nextColor = UIColor(hue: CGFloat(rnd), saturation: 1, brightness: 1, alpha: 0.8)
        nextGeometry.firstMaterial?.diffuse.contents = UIColor.black
        nextGeometry.segmentCount = 6
        let nextIndex = SIMD3(x: Int(gridPosition.x), y: Int(gridPosition.y), z: Int(gridPosition.z))
        let nextNode = NewNode(proxy: nextIndex, geometry: nextGeometry, color: UIColor.black)
        nextNode.position = gridPosition
        nextNode.name = "gridNode"
        print("nextNode \(nextNode.uid)")
        return nextNode
    }
    
    func debugNode(gridPosition:SCNVector3) -> SCNNode {
        let nextGeometry = SCNSphere(radius: 0.5)
        nextGeometry.firstMaterial?.diffuse.contents = UIColor.black.withAlphaComponent(0.5)
        nextGeometry.firstMaterial?.fillMode = .lines
        let nextIndex = SIMD3(x: Int(gridPosition.x), y: Int(gridPosition.y), z: Int(gridPosition.z))
        let nextNode = NewNode(proxy: nextIndex, geometry: nextGeometry, color: UIColor.black)
        nextNode.position = gridPosition
        nextNode.name = "debugNode"
        print("debugNode \(nextNode.uid)")
        return nextNode
    }
}



class NewNode:SCNNode {
    var uid = UUID()
    var proxy: SIMD3<Int>?
    var color: UIColor?
    
    init(proxy: SIMD3<Int>, geometry: SCNGeometry, color: UIColor) {
        super.init()
        self.geometry = geometry
        self.proxy = proxy
        self.color = color
      //  print("proxy \(self.proxy)")
        
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func changeColor(newColor: UIColor) {
        self.geometry?.firstMaterial?.diffuse.contents = newColor
    }
}
            
            

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension CGPoint {
    func scnVector3Value(view: SCNView, depth: Float) -> SCNVector3 {
        //let cords = view.pointOfView?.worldPosition
        let projectedOrigin = view.projectPoint(SCNVector3(0, 0, depth))
       
        return view.unprojectPoint(SCNVector3(Float(x), Float(y), projectedOrigin.z))
    }
}

protocol Changeable {}

extension Changeable {
    func changing<T>(path: WritableKeyPath<Self, T>, to value: T) -> Self {
        var clone = self
        clone[keyPath: path] = value
        return clone
    }
}

extension Array {
    func copiedElements() -> Array<Element> {
        return self.map{
            let copiable = $0 as! NSCopying
            return copiable.copy() as! Element
        }
    }
}


