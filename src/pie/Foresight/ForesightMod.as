package pie.Foresight 
{
	import Bezel.Bezel;
	import Bezel.BezelMod;
	import flash.display.MovieClip;
	/**
	 * ...
	 * @author Chris
	 */
	public class ForesightMod extends MovieClip implements BezelMod
	{
		
		private var foresight:Object;
		
		public function ForesightMod() 
		{
			super();
		}
		
		public function get VERSION():String { return "0.0.6"; }
		public function get GAME_VERSION():String { return "1.2.1a"; }
		public function get BEZEL_VERSION():String { return "1.0.0"; }
		public function get MOD_NAME():String { return "Foresight"; }
		
		public function bind(bezel:Bezel, gameObjects:Object): void
		{
			foresight = new Foresight(bezel, gameObjects);
		}
		
		public function unload(): void
		{
			if (foresight != null)
			{
				foresight.unload();
				foresight = null;
			}
		}
		
	}

}
