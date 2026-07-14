using Godot;
using System;

public partial class Audio : Node
{
	private AudioStreamPlayer moveSound;
	private AudioStreamPlayer mergeSound;
	private AudioStreamPlayer music;

	public override void _Ready()
	{
		moveSound = CreatePlayer("res://Audio/move.wav", -6.0f);
		mergeSound = CreatePlayer("res://Audio/merge.wav", -3.0f);

		music = CreatePlayer("res://Audio/music.wav", -14.0f);
		if (music.Stream is AudioStreamWav wav)
		{
			// Loop the background track seamlessly.
			int bytesPerFrame = wav.Format == AudioStreamWav.FormatEnum.Format16Bits ? 2 : 1;
			if (wav.Stereo) bytesPerFrame *= 2;

			wav.LoopMode = AudioStreamWav.LoopModeEnum.Forward;
			wav.LoopBegin = 0;
			wav.LoopEnd = wav.Data.Length / bytesPerFrame;
		}
		music.Play();
	}

	private AudioStreamPlayer CreatePlayer(string streamPath, float volumeDb)
	{
		AudioStreamPlayer player = new AudioStreamPlayer();
		player.Stream = GD.Load<AudioStream>(streamPath);
		player.VolumeDb = volumeDb;
		AddChild(player);
		return player;
	}

	// Called when tiles slide on a valid move.
	public void PlayMove()
	{
		moveSound.Play();
	}

	// Called when two tiles combine into a doubled tile.
	public void PlayMerge()
	{
		mergeSound.Play();
	}
}
