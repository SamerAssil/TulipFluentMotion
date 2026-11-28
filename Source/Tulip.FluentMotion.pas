{*******************************************************************************
  TulipFluentMotion - Fluent Animation & Motion Library for Delphi FMX

  Unit:      Tulip.FluentMotion
  Author:    Samer Assil
  Copyright: (c) 2026 Samer Assil
  License:   MIT (SPDX-License-Identifier: MIT)
*******************************************************************************}
unit Tulip.FluentMotion;

interface

uses
  FMX.Forms,
  FMX.Controls,
  Tulip.FluentMotion.Types,
  Tulip.FluentMotion.Interfaces,
  Tulip.FluentMotion.Phase,
  Tulip.FluentMotion.Engine,
  Tulip.FluentMotion.Driver,
  Tulip.FluentMotion.FormDriver,
  Tulip.FluentMotion.Builder,
  Tulip.FluentMotion.Helper,
  Tulip.FluentMotion.Effect.Base,
  Tulip.FluentMotion.Effect.Scale,
  Tulip.FluentMotion.Effect.Translate,
  Tulip.FluentMotion.Effect.Fade,
  Tulip.FluentMotion.Effect.Rotate,
  Tulip.FluentMotion.Effect.Flip3D,
  Tulip.FluentMotion.Effect.ColorTransition,
  Tulip.FluentMotion.Effect.Grayscale,
  Tulip.FluentMotion.Effect.Shadow,
  Tulip.FluentMotion.Effect.Shake,
  Tulip.FluentMotion.Effect.Pulse,
  Tulip.FluentMotion.Effect.Wait,
  Tulip.FluentMotion.Effect.Blur,
  Tulip.FluentMotion.Effect.Shimmer,
  Tulip.FluentMotion.Effect.Ripple,
  Tulip.FluentMotion.Effect.Transition,
  Tulip.FluentMotion.Effect.Glow,
  Tulip.FluentMotion.Effect.HueRotation,
  Tulip.FluentMotion.Effect.Wiggle,
  Tulip.FluentMotion.Effect.Resize,
  Tulip.FluentMotion.Effect.Shader,
  Tulip.FluentMotion.Effect.Text;

type
  { Re-export Core Types for convenient single-unit uses clause }
  TFluentEase = Tulip.FluentMotion.Types.TFluentEase;
  TFluentSpring = Tulip.FluentMotion.Types.TFluentSpring;
  TShimmerDirection = Tulip.FluentMotion.Types.TShimmerDirection;
  TFluentShimmerConfig = Tulip.FluentMotion.Types.TFluentShimmerConfig;
  TFluentRippleConfig = Tulip.FluentMotion.Types.TFluentRippleConfig;
  TFlipAxis = Tulip.FluentMotion.Types.TFlipAxis;
  TTransitionDirection = Tulip.FluentMotion.Types.TTransitionDirection;
  TMotionAnchor = Tulip.FluentMotion.Types.TMotionAnchor;
  TResizeAnchor = Tulip.FluentMotion.Types.TResizeAnchor;
  TFluentColorHelper = Tulip.FluentMotion.Types.TFluentColorHelper;

  TFluentTextHelper = Tulip.FluentMotion.Effect.Text.TFluentTextHelper;
  TFluentGraphemeHelper = Tulip.FluentMotion.Effect.Text.TFluentGraphemeHelper;
  TFluentCountEffect = Tulip.FluentMotion.Effect.Text.TFluentCountEffect;
  TFluentTypewriterEffect = Tulip.FluentMotion.Effect.Text.TFluentTypewriterEffect;
  TShaderDrawMode = Tulip.FluentMotion.Types.TShaderDrawMode;
  TShaderPreset = Tulip.FluentMotion.Types.TShaderPreset;
  TFluentGlassStyle = Tulip.FluentMotion.Types.TFluentGlassStyle;

  IMotionEffect = Tulip.FluentMotion.Interfaces.IMotionEffect;
  ITransformEffect = Tulip.FluentMotion.Interfaces.ITransformEffect;
  IAnchorableEffect = Tulip.FluentMotion.Interfaces.IAnchorableEffect;
  ISkiaPaintEffect = Tulip.FluentMotion.Interfaces.ISkiaPaintEffect;
  IMotionPhase = Tulip.FluentMotion.Interfaces.IMotionPhase;
  IMotionDriver = Tulip.FluentMotion.Interfaces.IMotionDriver;
  IMotionBuilder = Tulip.FluentMotion.Interfaces.IMotionBuilder;

  TFluentShaderEffect = Tulip.FluentMotion.Effect.Shader.TFluentShaderEffect;
  TFluentBorderBeamEffect = Tulip.FluentMotion.Effect.Shader.TFluentBorderBeamEffect;
  TFluentLiquidWaveEffect = Tulip.FluentMotion.Effect.Shader.TFluentLiquidWaveEffect;
  TFluentFrostedGlassEffect = Tulip.FluentMotion.Effect.Shader.TFluentFrostedGlassEffect;
  TFluentMeshGradientEffect = Tulip.FluentMotion.Effect.Shader.TFluentMeshGradientEffect;
  TFluentDissolveBurnEffect = Tulip.FluentMotion.Effect.Shader.TFluentDissolveBurnEffect;
  TFluentRippleDistortionEffect = Tulip.FluentMotion.Effect.Shader.TFluentRippleDistortionEffect;
  TFluentNeonGlowEffect = Tulip.FluentMotion.Effect.Shader.TFluentNeonGlowEffect;
  TFluentGooeyMetaballEffect = Tulip.FluentMotion.Effect.Shader.TFluentGooeyMetaballEffect;
  TFluentGlassEffect = Tulip.FluentMotion.Effect.Shader.TFluentGlassEffect;
  TFluentLiquidGlassEffect = Tulip.FluentMotion.Effect.Shader.TFluentLiquidGlassEffect;
  TFluentLiquidGlassGroupEffect = Tulip.FluentMotion.Effect.Shader.TFluentLiquidGlassGroupEffect;

  TFluentMotionDriver = Tulip.FluentMotion.Driver.TFluentMotionDriver;
  TFluentMotionFormDriver = Tulip.FluentMotion.FormDriver.TFluentMotionFormDriver;
  TFluentMotionControlHelper = class helper(Tulip.FluentMotion.Helper.TFluentMotionControlHelper) for TControl end;
  TFluentMotionFormHelper = class helper(Tulip.FluentMotion.Helper.TFluentMotionFormHelper) for TCommonCustomForm end;
  TFluentMotionEngine = Tulip.FluentMotion.Engine.TFluentMotionEngine;

implementation

end.
