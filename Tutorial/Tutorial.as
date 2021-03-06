package {
	import flare.animate.Easing;
	import flare.animate.Parallel;
	import flare.animate.Sequence;
	import flare.animate.Tween;
	
	import flash.display.Sprite;
	
	[SWF(width="800", height="600", backgroundColor="#ffffff", frameRate="30")]
	
	public class Tutorial extends Sprite
	{
		 private function createCircle(x:Number, y:Number):Sprite
        {
            var sprite:Sprite = new Sprite();
 
            sprite.graphics.beginFill(0xcccccc, 0.5);
            sprite.graphics.lineStyle(1, 0x000000);
            sprite.graphics.drawCircle(0, 0, 10);
            sprite.x = x;
            sprite.y = y;
            return sprite;
        }
        
		public function Tutorial()
		{
			var container:Sprite = new Sprite();
			
			container.x = 400;
			container.y = 300;
			 
            this.addChild(container);
			
			for (var i:int=0; i<10; ++i) {
                var x:Number = (i/5<1 ? 1 : -1) * (13 + 26 * (i%5));
                container.addChild(createCircle(x, 0));
            }
            
            var tween:Tween = new Tween(container, 3, {rotation:360});
            
            tween.easing = Easing.none;
    		//tween.play();
    		
    		var t1:Tween = new Tween(container, 1, {y:100});
    		var t2:Tween = new Tween(container, 1, {scaleX:2});
    		var t3:Tween = new Tween(container, 1, {y:300});
		    var t4:Tween = new Tween(container, 1, {scaleX:1});
 
		    var seq:Sequence = new Sequence(
       			new Parallel(t1, t2),
        		new Parallel(t3, t4)
    		);
    		
    	seq.play();
		}
	}
}
