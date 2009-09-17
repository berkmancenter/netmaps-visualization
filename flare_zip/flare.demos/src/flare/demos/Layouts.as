package flare.demos
{
	import flare.animate.FunctionSequence;
	import flare.animate.Transition;
	import flare.animate.TransitionEvent;
	import flare.animate.Transitioner;
	import flare.data.converters.JSONConverter;
	import flare.demos.util.Link;
	import flare.display.TextSprite;
	import flare.query.methods.add;
	import flare.util.Shapes;
	import flare.vis.Visualization;
	import flare.vis.controls.ClickControl;
	import flare.vis.controls.DragControl;
	import flare.vis.controls.ExpandControl;
	import flare.vis.controls.HoverControl;
	import flare.vis.controls.IControl;
	import flare.vis.data.Data;
	import flare.vis.data.DataList;
	import flare.vis.data.NodeSprite;
	import flare.vis.events.SelectionEvent;
	import flare.vis.operator.OperatorSwitch;
	import flare.vis.operator.encoder.PropertyEncoder;
	import flare.vis.operator.layout.BundledEdgeRouter;
	import flare.vis.operator.layout.CircleLayout;
	import flare.vis.operator.layout.CirclePackingLayout;
	import flare.vis.operator.layout.DendrogramLayout;
	import flare.vis.operator.layout.ForceDirectedLayout;
	import flare.vis.operator.layout.IcicleTreeLayout;
	import flare.vis.operator.layout.Layout;
	import flare.vis.operator.layout.RadialTreeLayout;
	
	import flash.events.*;
	import flash.external.*;
	import flash.net.*;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;	
	
	/**
	 * Demo showcasing a number of tree and graph layout algorithms.
	 */
	public class Layouts extends Demo
	{
		private var vis:Visualization;
		private var os:OperatorSwitch;
		private var shape:String = null;
		
		private var opt:Array;
		private var idx:int = -1;
		private var _detail:TextSprite;

		public function Layouts() {
			name = "Layouts";
		}
		
		
private function loadData(loader:URLLoader ):void 
{  
//var graphml_url:String = "http://dawn.law.harvard.edu:8085/asn_web_graphs/results/graphs/asn-Mongolia.graphml";
var graphml_url:String = root.loaderInfo.parameters.graphurl; 

var json_url:String    = root.loaderInfo.parameters.json_url;
//graphml_url = "http://localhost/asn_web_graphs/results/graphs/asn-Haiti.graphml";

if (json_url == null)
{
	json_url = "http://localhost/asn_web_graphs/country_json_summary.php/?cc=IR";
}
 trace("URL: " + json_url);
// if (graphml_url != "http://localhost/asn_web_graphs/results/graphs/asn-Haiti.graphml")
//{
//	//throw new Error("URL is:'" + graphml_url+ "'");
//}	
// //getURL("javascript:alert('Hello, world...')"); // mind the quotes again
  
// Wire up event listeners for our load process  
configListeners(loader); 
// Create a URL request with the path to the GraphML file 
var request:URLRequest = new URLRequest(json_url); 
try { 
// Initiate the loading process 
loader.load(request); 
} catch(error:Error) { 
throw("Unable to load requested document."); 
}  
} 

private static var data_cached:Data = null;

		static var gxml_loaded:Boolean = false;

private function completeHandler(event:Event):void { 
	var loader:URLLoader = URLLoader(event.target); 
		// Get XML from the loaded object 
				
	var jsc:JSONConverter = new JSONConverter();
	
	var arr:Array = jsc.parse(loader.data, null);
	
	var data:Data = new Data();
	
	var asn_to_node:Dictionary = new Dictionary();
	
	for each (var o:Object in arr) {
     var nodeSprite:NodeSprite = data.addNode(o);
     asn_to_node[o['asn']] = nodeSprite;
    }

	for each (var o:Object in arr) {
     var nodeSprite:NodeSprite = asn_to_node[o['asn']];
     var customers:Array  = o['customers'];
     
     for each (var customer:String in customers)
     {
     	if (asn_to_node[customer])
     	{
     		var customer_node:NodeSprite = asn_to_node[customer];
     		data.addEdgeFor(nodeSprite, customer_node);
     	}    	
     }
    }    
    
		
/* 	var graphML:XML = new XML(loader.data); 
 
			// Use Flare converter to convert GraphML to dataset  
	var gmlc:GraphMLConverter = new GraphMLConverter(); 
	var dataSet:DataSet = gmlc.parse(graphML); 
	var data:Data = Data.fromDataSet(dataSet);  
	
	data_cached = data;
		 */
 	_init(data); 	
 }
	 	
private function configListeners(dispatcher:IEventDispatcher):void { 
// Add a completion event listener 
dispatcher.addEventListener(Event.COMPLETE, completeHandler);  
} 
    public function asnGraph():void
	    {
			
			// Create an Actionscript URL loader 
			var loader:URLLoader = new URLLoader(); 
			loadData(loader);
	    }    
	    
		public override function init():void
		{
			// create a collection of layout options
			opt = options(bounds.width, bounds.height);
			idx = 0;
			if (data_cached == null)
			{
				asnGraph();
			}
			else
			{
				_init(data_cached);			
			}
		}
		
		private function _init(data:Data):void
		{	
			// create data and set defaults
			//var data:Data = GraphUtil.diamondTree(3,4,4);
			/*data.nodes.setProperties(opt[idx].nodes);
			data.edges.setProperties(opt[idx].edges);
			for (var j:int=0; j<data.nodes.length; ++j) {
				data.nodes[j].data.label = String(j);
				data.nodes[j].buttonMode = true;
			}
			*/
			
			// sort to ensure that children nodes are drawn over parents
			//data.nodes.sortBy("depth");
			//var treebuilder:TreeBuilder = new TreeBuilder();
			
			//treebuilder.calculate(data, data.nodes[0]);
			
			//data.tree = treebuilder.tree;
			
			// create the visualization
			vis = new Visualization(data);
			vis.bounds.x = bounds.x;
			vis.bounds.y = bounds.y + (0.06 * bounds.height);
			
			vis.bounds.width = bounds.width;
			vis.bounds.height = bounds.height - (0.10 * bounds.height);
			
			
			vis.operators.add(opt[idx].op);
			vis.setOperator("nodes", new PropertyEncoder(opt[idx].nodes, "nodes"));
			vis.setOperator("edges", new PropertyEncoder(opt[idx].edges, "edges"));
			vis.controls.add(new HoverControl(NodeSprite,
				// by default, move highlighted items to front
				HoverControl.MOVE_AND_RETURN,
				// highlight node border on mouse over
				function(e:SelectionEvent):void {
					e.node.lineWidth = 2;
					e.node.lineColor = 0x88ff0000;
				},
				// remove highlight on mouse out
				function(e:SelectionEvent):void {
					e.node.lineWidth = 0;
					e.node.lineColor = opt[idx].nodes.lineColor;
				}));
			
			vis.controls.add(new ClickControl (NodeSprite,
			1,
			function(evt:SelectionEvent):void {
				evt.node.lineColor = 0xFF00cc;		
				evt.node.fillColor = 0X00FF00; 
			},
			function(evt:SelectionEvent):void {
				evt.node.lineColor = 0xFF0Fcc;	
				evt.node.fillColor = 0X00FF00; 	 
			}));
				
			// add mouse-over details
			vis.controls.add(new HoverControl(NodeSprite,
				HoverControl.DONT_MOVE,
				function(evt:SelectionEvent):void {
					_detail.text = evt.node.data.asn;
				},
				function(evt:SelectionEvent):void {
					_detail.text = vis.data.nodes.length + " asns";
				}
			));
	
			vis.controls.add(opt[idx].ctrl);
			
			//addDetail();
			
			vis.continuousUpdates = false;
			vis.update();
			//addChild(vis);
			addDetail();
			// create links for switching between layouts
			for (var i:uint=0; i<opt.length; ++i) {
				var link:Link = new Link(opt[i].name);
				link.addEventListener(MouseEvent.CLICK, function(event:MouseEvent):void {
					switchTo(event.target.text).play();
				});
				links.add(link);
				if (i==0) links.select(link);
			}
		}
		
		private function addDetail():void
		{	
			var fmt:TextFormat = new TextFormat("Verdana",14);
			
			/*
			_legend = Legend.fromValues(null, [
				{color: 0xffff0000, size: 0.75, label: "Imports"},
				{color: 0xff00ff00, size: 0.75, label: "Is Imported By"}
			]);
			_legend.labelTextFormat = fmt;
			_legend.labelTextMode = TextSprite.EMBED;
			_legend.update();
			addChild(_legend);
			*/
			
			_detail = new TextSprite("");
			_detail.textField.multiline = true;
			_detail.htmlText = vis.data.nodes.length + " asns";

			_detail.y = bounds.height - _detail.height - 15;

			vis.addChild(_detail);
			//_detail.height = _detail.height + 100;
			//addChild(_detail);
		}
		

		public override function resize():void
		{
			bounds.x += 15; bounds.width -= 30;
			bounds.y += 15;	bounds.height -= 15;
			if (vis) {
				vis.bounds = bounds;
				vis.update();
			}
		}
				
		private function switchTo(name:String):Transition
		{
			// determine the old and current layouts
			var old:Object = opt[idx];
			for (idx=0; idx<opt.length; ++idx) {
				if (opt[idx].name == name) break;
			}
			var cur:Object = opt[idx];
			
			// initialize the visualization
			vis.continuousUpdates = false;
			vis.operators.clear();
			vis.operators.add(cur.op);
			vis.setOperator("nodes", new PropertyEncoder(cur.nodes, "nodes"));
			vis.setOperator("edges", new PropertyEncoder(cur.edges, "edges"));
			// update controls
			HoverControl(vis.controls[0]).movePolicy = cur.dontMove
				? HoverControl.DONT_MOVE : HoverControl.MOVE_AND_RETURN;
			vis.controls.removeControlAt(1);
			if (cur.ctrl != null) vis.controls.add(cur.ctrl);
			
			// To handle animated transtions, we use a function sequence
			// this is like a normal animation sequence, except that each
			// animation segment is created lazily by a function when needed,
			// rather than generating the values for all segments up front.
			// This can help simplify the handling of intermediate values.
			var seq:FunctionSequence = new FunctionSequence();
			var nodes:DataList = vis.data.nodes;
			var edges:DataList = vis.data.edges;
			
			// First, straighten any edge-bends as needed
			if (old.straighten && !(cur.straighten || cur.canStraighten)) {
				seq.add(Layout.straightenEdges(edges, new Transitioner(1)));
			}
			// Now, build the main body of the animation
			if (old.nodes.shape != cur.nodes.shape) {
				if (old.nodes.shape == Shapes.CIRCLE) {
					// If the preceding shape is a circle, re-layout the nodes
					// first, then grow into the new shape type
					if (old.nodes.size != cur.nodes.size)
						seq.push(nodes.setLater({size: cur.nodes.size}), 0.5);
					seq.push(vis.updateLater(), 2);
					seq.push(vis.updateLater("edges"), 0.5);
					seq.push(nodes.setLater({scaleX:0, scaleY:0}), 0.5);
					seq.push(vis.updateLater("nodes"), 0);
					seq.push(nodes.setLater({scaleX:1, scaleY:1}), 0.5);
				} else if (cur.nodes.shape == Shapes.CIRCLE) {
					// If the current shape is a circle, change the shape type
					// first, and then re-layout the nodes
					seq.push(nodes.setLater({scaleX:0, scaleY:0}), 0.5);
					seq.push(vis.updateLater("nodes", "edges"), 0);
					seq.push(nodes.setLater({scaleX:1, scaleY:1}), 0.5);
					if (!cur.update)
						seq.push(vis.updateLater(), 2);
				} else {
					// If neither shape is a circle, switch to a circle shape,
					// re-layout the nodes, then switch to the final shape
					seq.push(nodes.setLater({scaleX:0, scaleY:0}), 0.5);
					seq.push(nodes.setLater({shape: Shapes.CIRCLE, size:1}), 0);
					seq.push(nodes.setLater({scaleX:1, scaleY:1}), 0.25);
					seq.push(vis.updateLater(), 2);
					seq.push(nodes.setLater({scaleX:0, scaleY:0}), 0.25);
					seq.push(vis.updateLater("nodes","edges"), 0);
					seq.push(nodes.setLater({scaleX:1, scaleY:1}), 0.5);
				}
			} else if (!cur.update) {
				// If there is no change in shape, update everything at once
				seq.push(vis.updateLater("nodes", "edges", "main"), 2);
			}
			// Finally, if performing a force-directed layout, set up
			// continuous updates and ease in the edge tensions.
			if (cur.update) {
				cur.op.defaultSpringTension = 0;
				seq.addEventListener(TransitionEvent.END,
					function(evt:Event):void {
						var t:Transitioner = vis.update(2, "nodes", "edges");
						t.$(cur.op).defaultSpringTension =
							cur.param.defaultSpringTension;
						t.play();
						vis.continuousUpdates = true;
					}
				);
			}
			return seq;
		}
		
		public override function play():void
		{
			if (opt[idx].update) vis.continuousUpdates = true;
		}
		
		public override function stop():void
		{
			vis.continuousUpdates = false;
		}
		
		/**
		 * This method builds a collection of layout operators and node
		 * and edge settings to be applied in the demo.
		 */
		private function options(w:Number, h:Number):Array
		{
			var a:Array = [
//				{
//					name: "Tree",
//					op: new NodeLinkTreeLayout("topToBottom",20,5,10),
//					canStraighten: true
//				},
				{
					name: "Circle",
					op: new CircleLayout(null, null, true),
					param: {angleWidth: -2*Math.PI},
					ctrl: new DragControl(NodeSprite)
				},

				{
					name: "Force",
					op: new ForceDirectedLayout(true),
					param: {
						"simulation.dragForce.drag": 0.2,
						defaultParticleMass: 3,
						defaultSpringLength: 100,
						defaultSpringTension: 0.1
						//,
//
//									restLength : function(es:EdgeSprite):Number {	var minEdgeLength:int = 100;
//				var maxEdgeLength:int = 200;
//				return minEdgeLength + (maxEdgeLength - minEdgeLength) * (es.data.weight - minWeight)/(maxWeight - minWeight) ;
//			}	
					},
					update: true,
					ctrl: new DragControl(NodeSprite)
				},
//				{
//					name: "Indent",
//					op: new IndentedTreeLayout(20),
//					param: {layoutAnchor: new Point(350,40)},
//					straighten: true
//				},
//				{
//					name: "Radial",
//					op: new RadialTreeLayout(50, false),
//					param: {angleWidth: -2*Math.PI}
//				},
				{
					name: "Dendrogram",
					op: new DendrogramLayout(),
					nodes: {alpha: 0, visible: false},
					edges: {lineWidth:2},
					straighten: true
				},
				{
					name: "Bubbles",
					op: new CirclePackingLayout(4, false, "depth"),
					nodes: {size: add(1, "depth")},
					edges: {alpha:0, visible:false},
					ctrl: new DragControl(NodeSprite),
					canStraighten: true
				},
				{
					name: "Circle Pack",
					op: new CirclePackingLayout(4, true, "childDegree"),
					edges: {alpha:0, visible:false},
					canStraighten: true,
					dontMove: true
				},
				{
					name: "Icicle",
					op:	new IcicleTreeLayout("topToBottom"),
					nodes: {shape: Shapes.BLOCK, lineColor: 0xffffffff},
					edges: {alpha: 0, visible:false}
				},
				{
					name: "BundledEdgeRouter",
					op:	new BundledEdgeRouter()
					//, 
					/* param: {angleWidth: -2*Math.PI},
					nodes: {shape: Shapes.BLOCK, lineColor: 0xffffffff},
					edges: {alpha: 0, visible:false} */
				},
				{
					name: "Sunburst",
					op: new RadialTreeLayout(50, false),
					param: {angleWidth: -2*Math.PI},
					nodes: {shape: Shapes.WEDGE, lineColor: 0xffffffff},
					edges: {alpha: 0, visible:false}
				}
			];
			
			// default values
			var nodes:Object = {
				shape: Shapes.CIRCLE,
				fillColor: 0x88aaaaaa,
				lineColor: 0xdddddddd,
				lineWidth: 1,
				size: 1.5,
				alpha: 1,
				visible: true
			}
			var edges:Object = {
				lineColor: 0xffcccccc,
				lineWidth: 1,
				alpha: 1,
				visible: true
			}
			var ctrl:IControl = new ExpandControl(NodeSprite,
				function():void { vis.update(1, "nodes","main").play(); });
			
			// apply defaults where needed
			var name:String;
			for each (var o:Object in a) {
				if (!o.nodes)
					o.nodes = nodes;
				else for (name in nodes)
					if (o.nodes[name]==undefined)
						o.nodes[name] = nodes[name];
					
				if (!o.edges)
					o.edges = edges;
				else for (name in edges)
					if (o.edges[name]==undefined)
						o.edges[name] = edges[name];
				
				if (!("ctrl" in o)) o.ctrl = ctrl;
				if (o.param) o.op.parameters = o.param;
			}
			return a;
		}
		
	} // end of class Layouts
}