using Godot;
using System;
using System.Collections.Generic;

public partial class Grid : Node2D
{
	[Signal]
	public delegate void ScoreUpdateEventHandler(int additionalPoints);
	[Signal]
	public delegate void GameOverEventHandler();
	[Signal]
	public delegate void MovedEventHandler();
	[Signal]
	public delegate void MergedEventHandler();
	

	private Tile[,] grid;
	private PackedScene sceneTile;

	public override void _Ready()
	{

		sceneTile = ResourceLoader.Load<PackedScene>("res://Prefabs/tile.tscn");

		grid = new Tile[4, 4];	

		PopulateStartingTiles();

	}

	public override void _Process(double delta)
	{
	}

    public override void _Input(InputEvent @event)
    {
		bool moved = false;

        if (@event.IsActionPressed("up"))
		{
			moved = MoveTiles("up");
		}

		if (@event.IsActionPressed("down"))
		{
			moved = MoveTiles("down");
		}

		if (@event.IsActionPressed("left"))
		{
			moved = MoveTiles("left");
		}

		if (@event.IsActionPressed("right"))
		{
			moved = MoveTiles("right");
		}

		if (moved) 
		{
			SpawnRandomTile();
		}
    }

    private bool MoveTiles(String direction) {
		GD.Print("MoveTiles() called. " + direction);
		bool movementOccurred = false;

		bool isHorizontal = direction == "left" || direction == "right";
		bool isReverse = direction == "up" || direction == "left";

		Dictionary<Tile, Vector2> mergeCoords = new Dictionary<Tile, Vector2>();
		Dictionary<Tile, Vector2> originalPositions = new Dictionary<Tile, Vector2>();

		int pointsScored = 0;

		for (int i = 0; i < 4; i++) {
			Stack<Tile> tiles = new Stack<Tile>();

			for (int j = 0; j < 4; j++) {
				int x = isHorizontal ? (isReverse ? 3 - j : j) : i;
				int y = isHorizontal ? i : (isReverse ? 3 - j : j);

				if (grid[x, y] != null)
				{
					originalPositions[grid[x, y]] = new Vector2(x, y);
					tiles.Push(grid[x, y]);
					grid[x, y] = null;
				}
			}

			int newIndex = isReverse ? 0 : 3;

			while (tiles.Count > 0)
			{
				Tile current = tiles.Pop();
				Tile next = tiles.Count > 0 ? tiles.Peek() : null;
				Tile merged = null;

				// Check for merge
				if (next != null && current.GetValue() == next.GetValue())
				{
					movementOccurred = true;

					pointsScored += current.GetValue() * 2;

					merged = tiles.Pop();
					current.SetValue(current.GetValue() * 2);
				}

				if (isHorizontal)
				{
					grid[newIndex, i] = current;
					if (merged != null)
					{
						mergeCoords.Add(merged, ArrayToTileCoords(new Vector2(newIndex, i)));
					}
				}
				else {
					grid[i, newIndex] = current;
					if (merged != null)
					{
						mergeCoords.Add(merged, ArrayToTileCoords(new Vector2(i, newIndex)));
					}
				}

				newIndex += isReverse ? 1 : -1;

			}

		}

		foreach (Tile t in originalPositions.Keys) {
			Vector2 coords = originalPositions[t];
			if (grid[(int) coords.X, (int) coords.Y] != t) {
				movementOccurred = true;
				break;
			}
		}

		for (int x = 0; x < 4; x++)
		{
			for (int y = 0; y < 4; y++)
			{
				if (grid[x, y] != null)
				{
					Tile t = grid[x, y];
					Tween tween = t.CreateTween();
					tween.TweenProperty(
						t,
						"position",
						ArrayToTileCoords(new Vector2(x, y)),
						0.1f
					);
				}
			}
		}

		foreach (Tile t in mergeCoords.Keys)
		{
			Vector2 coords = mergeCoords[t];
			Tween tween = t.CreateTween();
			tween.TweenProperty(t,
								"position",
								coords,
								0.1f);
			tween.TweenCallback(Callable.From(() => { t.QueueFree(); } ));
		}

		EmitSignal(SignalName.ScoreUpdate, pointsScored);

		if (movementOccurred) EmitSignal(SignalName.Moved);
		if (mergeCoords.Count > 0) EmitSignal(SignalName.Merged);

		if (CheckGameOver()) EmitSignal(SignalName.GameOver);

		return movementOccurred;
	}

	private void SpawnRandomTile() {
		List<Vector2I> spaces = new List<Vector2I>();

		for (int x = 0; x < 4; x++) 
		{
			for (int y = 0; y < 4; y++)
			{
				if (grid[x ,y] == null) {
					spaces.Add(new Vector2I(x, y));
				}
			}
		}

		if (spaces.Count > 0)
		{
			Random r = new Random();
			int selection = r.Next(0, spaces.Count);
			SpawnTile(spaces[selection].X, spaces[selection].Y);
		}
	}

	private void SpawnTile(int x, int y) {
		Random r = new Random();

		Tile newTile = sceneTile.Instantiate() as Tile;
		newTile.Position = ArrayToTileCoords(new Vector2(x, y));

		int spawn4 = r.Next(0, 10);
		int value = spawn4 > 7 ? 4 : 2;
		newTile.SetValue(value);

		grid[x, y] = newTile;
		AddChild(newTile);
	}


	private Vector2 ArrayToTileCoords(Vector2 arrayCoords) {
		return new Vector2(arrayCoords.X * 115 + 15, arrayCoords.Y * 115 + 15);
	}

	private void PopulateStartingTiles() {

		Random rand = new Random();

		Vector2 tile1coords = new Vector2(rand.Next(0, 4), rand.Next(0, 4));
		Vector2 tile2coords = new Vector2(rand.Next(0, 4), rand.Next(0, 4));

		while (tile1coords.X == tile2coords.X && tile1coords.Y == tile2coords.Y) {
			tile1coords = new Vector2(rand.Next(0, 4), rand.Next(0, 4));
			tile2coords = new Vector2(rand.Next(0, 4), rand.Next(0, 4));
		} 

		Tile t1 = sceneTile.Instantiate() as Tile;
		t1.Position = ArrayToTileCoords(tile1coords);
		t1.SetValue(2);
		AddChild(t1);

		Tile t2 = sceneTile.Instantiate() as Tile;
		t2.Position = ArrayToTileCoords(tile2coords);
		t2.SetValue(2);
		AddChild(t2);

		grid[(int) tile1coords.X, (int) tile1coords.Y] = t1;
		grid[(int) tile2coords.X, (int) tile2coords.Y] = t2;
	}

	private bool CheckGameOver()
	{
		for (int x = 0; x < 4; x++)
		{
			for (int y = 0; y < 4; y++)
			{
				if (grid[x, y] == null)
				{
					return false;
				} else {
					var adjacentPositions = new (int, int)[]
					{
						(x + 1, y),
						(x - 1, y),
						(x, y + 1),
						(x, y - 1)
					};

					foreach (var p in adjacentPositions)
					{
						if (p.Item1 >= 0 && p.Item1 < 4 && p.Item2 >= 0 && p.Item2 < 4)
						{
							if (grid[p.Item1, p.Item2] == null) return false;
							if (grid[x, y].GetValue() == grid[p.Item1, p.Item2].GetValue()) return false;
						}
					}
				}
			}
		}

		return true;
	}


	public void Reset()
	{
		for (int x = 0; x < 4; x++)
		{
			for (int y = 0; y < 4; y++)
			{
				if (grid[x, y] != null)
				{
					grid[x, y].QueueFree();
					grid[x, y] = null;
				}
			}
		}

		PopulateStartingTiles();
	}
}
