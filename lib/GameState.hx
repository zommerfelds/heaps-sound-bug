class GameState extends h2d.Scene {
	public function onBackButton() {}

	public function update(timeStep:Float) {}

	// NOTE: it's currently not very clear why there should be a separate render function, as
	//       in Heaps they are called just one after the other. For other games it may be useful
	//       to implement a fixed time step loop.
	public function renderUpdate() {}

	public function init() {}

	public function cleanup() {}
}
