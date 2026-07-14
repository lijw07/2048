using Godot;
using System;

public partial class Score : Control
{

	private Label valueLabel;

	public override void _Ready()
	{
		valueLabel = GetNode<Label>("Panel/ScoreValue");
	}

	public override void _Process(double delta)
	{
	}

	public void AddToScore(int additionalValue) 
	{
		int currentValue = int.Parse(valueLabel.Text);
		int newValue = currentValue + additionalValue;
		valueLabel.Text = "" + newValue;
	}

	public void Reset()
	{
		valueLabel.Text = "" + 0;
	}
}
