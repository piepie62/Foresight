package pie.Foresight
{
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.utils.*;
	import flash.events.MouseEvent;
	
	/**
	 * ...
	 * @author piepie62
	 */
	public class Foresight extends MovieClip
	{
		public const VERSION:String = "0.0.2";
		public const GAME_VERSION:String = "1.1.2b";
		public const BEZEL_VERSION:String = "0.2.1";
		public const MOD_NAME:String = "Foresight";
		
		internal var bezel:Object;
		internal var gameObjects:Object;
		internal var logger:Object;
		
		// Game object shortcuts
		internal var core:Object;/*IngameCore*/
		internal var cnt:Object;/*CntIngame*/
		internal var GV:Object;/*GV*/
		internal var SB:Object;/*SB*/
		internal var prefs:Object;/*Prefs*/
		
		private static var keycodes:Class;
		
		private var placingType:int;
		
		private var images:Array;
		private var cursorImage:MovieClip;
		
		private var currentStage:Object;
		
		public function Foresight() 
		{
			super();
		}
		
		public function bind(modLoader:Object, gameObjects:Object): Foresight
		{
			this.bezel = modLoader;
			this.logger = modLoader.getLogger("Foresight");
			
			this.gameObjects = gameObjects;
			this.core = gameObjects.GV.ingameCore;
			this.cnt = gameObjects.GV.main.cntScreens.cntIngame;
			this.SB = gameObjects.SB;
			this.GV = gameObjects.GV;
			this.prefs = gameObjects.prefs;
			
			this.placingType = -1;
			this.images = new Array();
			for (var x:int = 0; x < 60; x++)
			{
				this.images.push(new Array());
				for (var y:int = 0; y < 38; y++)
				{
					this.images[x].push(new MovieClip());
					this.images[x][y].x = x * 28 + 46;
					this.images[x][y].y = y * 28 + 4;
					this.images[x][y].visible = true;
				}
			}
			this.cursorImage = new MovieClip();
			this.cursorImage.visible = true;
			this.currentStage = null;
			
			keycodes = getDefinitionByName("com.giab.common.constants.KeyCode") as Class;
			
			installEventHooks(modLoader);
			
			logger.log("bind", "Foresight loaded");
			
			return this;
		}
		
		public function installEventHooks(modLoader:Object): void
		{
			bezel.addEventListener("ingameClickOnScene", clickOnSceneHook);
			bezel.addEventListener("ingameRightClickOnScene", rightClickOnSceneHook);
			bezel.addEventListener("ingameKeyDown", keyDownHook);
			GV.main.addEventListener("enterFrame", frameHook);
		}
		
		public function unload(): void
		{
			bezel.removeEventListener("ingameClickOnScene", clickOnSceneHook);
			bezel.removeEventListener("ingameRightClickOnScene", rightClickOnSceneHook);
			bezel.removeEventListener("ingameKeyDown", keyDownHook);
			GV.main.removeEventListener("enterFrame", frameHook);
			
			var hud:Object = core.cnt.cntRetinaHud;
			for (var x:int = 0; x < 60; x++)
			{
				for (var y:int = 0; y < 38; y++)
				{
					if (hud.contains(images[x][y]))
					{
						hud.removeChild(images[x][y]);
					}
				}
			}
			if (hud.contains(cursorImage))
			{
				hud.removeChild(cursorImage);
			}
		}
		
		public function clickOnSceneHook(e:Object): void
		{
			var event:MouseEvent = e.eventArgs.event;
			if (placingType != -1)
			{
				var x:int = buildX(GV.main.mouseX);
				var y:int = buildY(GV.main.mouseY);
				
				if (x >= 0 && y >= 0)
				{
					images[x][y].removeChildren();
					images[x][y].addChild(createImageFor(placingType));
				}
			}
		}
		
		public function rightClickOnSceneHook(e:Object): void
		{
			if (placingType != -1)
			{
				cursorImage.removeChildren();
				placingType = -1;
			}
			else
			{
				var x:int = buildX(GV.main.mouseX);
				var y:int = buildY(GV.main.mouseY);
				// if it's valid and a wall
				if (images[x][y].numChildren != 0 && images[x][y].getChildAt(0) is (getDefinitionByName(getQualifiedClassName(core.cnt.mcBuildHelperWallLine)) as Class))
				{
					images[x][y].removeChildren();
				}
				else
				{
					for each (var xMod:int in [ -1, 0])
					{
						for each (var yMod:int in [ -1, 0])
						{
							// If it's valid and not a wall
							if (x + xMod >= 0 && x + xMod < 60 && y + yMod >= 0 && y + yMod < 38
								&& images[x + xMod][y + yMod].numChildren != 0 &&
								!(images[x + xMod][y + yMod].getChildAt(0) is (getDefinitionByName(getQualifiedClassName(core.cnt.mcBuildHelperWallLine)) as Class)))
							{
								images[x + xMod][y + yMod].removeChildren();
							}
						}
					}
				}
			}
		}
		
		public function keyDownHook(e:Object): void
		{
			var event:KeyboardEvent = e.eventArgs.event;
			if (event.ctrlKey)
			{
				var type:int = typeFromKeycode(event.keyCode);
				if (type != -1 && placingType != type)
				{
					cursorImage.removeChildren();
					e.eventArgs.continueDefault = false;
					this.placingType = type;
					cursorImage.addChild(createImageFor(placingType));
				}
				else if (type != -1 && placingType == type)
				{
					e.eventArgs.continueDefault = false;
					cursorImage.removeChildren();
					this.placingType = -1;
				}
			}
		}
		
		public function frameHook(event:Object): void
		{
			var hud:Object = core.cnt.cntRetinaHud;
			if (this.currentStage != core.stageData)
			{
				clearImages();
				this.placingType = -1;
				this.currentStage = core.stageData;
				return;
			}
			
			ensureLoadedImages();
			
			if (placingType == -1)
			{
				hud.removeChild(cursorImage);
			}
			else
			{
				cursorImage.x = buildX(GV.main.mouseX) * 28 + 46;
				cursorImage.y = buildY(GV.main.mouseY) * 28 + 4;
				hud.addChild(cursorImage);
			}
		}
		
		private function clearImages(): void
		{
			for (var x:int = 0; x < 60; x++)
			{
				for (var y:int = 0; y < 38; y++)
				{
					images[x][y].removeChildren();
				}
			}
		}
		
		private static function typeFromKeycode(code:uint): int
		{
			switch (code)
			{
				// Tower
				case keycodes.T:
					return 0;
				// Wall
				case keycodes.W:
					return 1;
				// Trap
				case keycodes.R:
					return 2;
				// Lantern
				case keycodes.L:
					return 3;
				// Amplifier
				case keycodes.A:
					return 4;
				// Pylons
				case keycodes.P:
					return 5;
			}
			return -1;
		}
		
		private static function buildX(x:int): int
		{
			var ret:int = x - 50;
			if (ret >= 0 && ret / 28 < 60)
			{
				return Math.floor(ret / 28);
			}
			else
			{
				return -1;
			}
		}
		
		private static function buildY(y:int): int
		{
			var ret:int = y - 8;
			if (ret >= 0 && ret / 28 < 60)
			{
				return Math.floor(ret / 28);
			}
			else
			{
				return -1;
			}
		}
		
		private function createImageFor(type:int): *
		{
			switch (type)
			{
				case 0:
					return new Bitmap(core.cnt.bmpBuildHelperTower.bitmapData);
				case 1:
					var ret:Object = new (getDefinitionByName(getQualifiedClassName(core.cnt.mcBuildHelperWallLine)))();
					ret.gotoAndStop(1);
					ret.x = 4;
					ret.y = 4;
					return ret;
				case 2:
					return new Bitmap(core.cnt.bmpBuildHelperTrap.bitmapData);
				case 3:
					return new Bitmap(core.cnt.bmpBuildHelperLantern.bitmapData);
				case 4:
					return new Bitmap(core.cnt.bmpBuildHelperAmp.bitmapData);
				case 5:
					return new Bitmap(core.cnt.bmpBuildHelperPylon.bitmapData);
			}
			return null;
		}
		
		private function ensureLoadedImages(): void
		{
			if (!core.cnt.cntRetinaHud.contains(this.images[0][0]))
			{
				for (var x:int = 0; x < 60; x++)
				{
					for (var y:int = 0; y < 38; y++)
					{
						core.cnt.cntRetinaHud.addChild(this.images[x][y]);
					}
				}
			}
		}
	}
	
}