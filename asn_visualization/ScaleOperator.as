package
{
	import flare.animate.Transitioner;
	import flare.vis.data.NodeSprite;
	import flare.vis.operator.Operator;

	public class ScaleOperator extends Operator
	{
		public function ScaleOperator()
		{
			super();
		}
		
		 	
		public override function operate(t:Transitioner = null):void
		{
			if (visualization.height > visualization.bounds.height)
			{
				var scale_factor:Number = visualization.bounds.height/visualization.height;
				
				visualization.scaleX = scale_factor;
				visualization.scaleY = scale_factor;
			} 
			
			for each (var _node:NodeSprite in visualization.data.nodes)
			{
				_node.dirty();
			}
		}
	}
}