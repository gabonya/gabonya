import { loadFont } from "@remotion/google-fonts/CormorantGaramond";
import React from "react";
import {
  AbsoluteFill,
  Composition,
  Easing,
  Img,
  interpolate,
  Sequence,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from "remotion";

const { fontFamily } = loadFont("normal", {
  weights: ["500", "700"],
  subsets: ["cyrillic", "latin"],
});

const FPS = 30;
const DURATION = 10 * FPS;

const clamp = {
  extrapolateLeft: "clamp",
  extrapolateRight: "clamp",
} as const;

// Story beats (frames)
const BEAT = {
  forestEnd: 80,
  sitStart: 60,
  sitEnd: 155,
  snarlStart: 155,
  snarlEnd: 215,
  leapStart: 215,
  leapEnd: 252,
  titleStart: 250,
};

export const MyComposition = () => {
  return (
    <Composition
      id="FogGuardian"
      component={FogGuardian}
      durationInFrames={DURATION}
      fps={FPS}
      width={1080}
      height={1920}
    />
  );
};

const Fog: React.FC<{ opacity: number; speed: number; offset: number }> = ({
  opacity,
  speed,
  offset,
}) => {
  const frame = useCurrentFrame();
  const x = ((frame * speed + offset) % 2160) - 1080;
  return (
    <AbsoluteFill style={{ opacity, mixBlendMode: "screen" }}>
      {[0, 1].map((i) => (
        <div
          key={i}
          style={{
            position: "absolute",
            left: x + i * 2160 - 2160,
            top: 700,
            width: 3240,
            height: 900,
            background:
              "radial-gradient(ellipse at 30% 50%, rgba(170,195,200,0.55), transparent 60%), radial-gradient(ellipse at 75% 40%, rgba(150,180,190,0.45), transparent 55%)",
            filter: "blur(40px)",
          }}
        />
      ))}
    </AbsoluteFill>
  );
};

const Caption: React.FC<{ text: string; from: number; to: number }> = ({
  text,
  from,
  to,
}) => {
  const frame = useCurrentFrame();
  const opacity = interpolate(
    frame,
    [from, from + 12, to - 12, to],
    [0, 1, 1, 0],
    clamp,
  );
  const y = interpolate(frame, [from, to], [20, -10], clamp);
  return (
    <AbsoluteFill
      style={{
        justifyContent: "flex-end",
        alignItems: "center",
        paddingBottom: 260,
      }}
    >
      <div
        style={{
          fontFamily,
          fontWeight: 500,
          fontStyle: "italic",
          fontSize: 64,
          lineHeight: 1.2,
          color: "#dfe9ec",
          textAlign: "center",
          maxWidth: 900,
          opacity,
          transform: `translateY(${y}px)`,
          textShadow: "0 0 30px rgba(0,0,0,0.9), 0 2px 8px rgba(0,0,0,0.8)",
        }}
      >
        {text}
      </div>
    </AbsoluteFill>
  );
};

const creatureLook: React.CSSProperties = {
  position: "absolute",
  filter:
    "brightness(0.82) saturate(0.85) drop-shadow(0 0 30px rgba(150,220,255,0.45))",
};

export const FogGuardian: React.FC = () => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  // Slow camera push into the forest, then a hard punch-in at the snarl
  const push = interpolate(frame, [0, BEAT.snarlStart], [1.05, 1.25], {
    ...clamp,
    easing: Easing.inOut(Easing.quad),
  });
  const punch = spring({
    frame: frame - BEAT.snarlStart,
    fps,
    config: { damping: 14, stiffness: 120 },
  });
  const camScale = push + punch * 0.25;

  // Camera shake during the snarl and leap
  const shakeAmt = interpolate(
    frame,
    [BEAT.snarlStart, BEAT.snarlStart + 6, BEAT.snarlEnd, BEAT.leapEnd],
    [0, 14, 6, 22],
    clamp,
  );
  const shakeX = Math.sin(frame * 2.3) * shakeAmt;
  const shakeY = Math.cos(frame * 3.1) * shakeAmt * 0.6;

  const forestDarken = interpolate(frame, [0, 20], [1, 0], clamp);
  const sceneFadeOut = interpolate(
    frame,
    [BEAT.leapEnd - 4, BEAT.leapEnd],
    [1, 0],
    clamp,
  );

  // --- Sitting guardian emerges from the fog
  const sitOpacity = interpolate(
    frame,
    [BEAT.sitStart, BEAT.sitStart + 40, BEAT.sitEnd - 6, BEAT.sitEnd],
    [0, 0.9, 0.9, 0],
    clamp,
  );
  const sitBlur = interpolate(
    frame,
    [BEAT.sitStart, BEAT.sitStart + 45],
    [14, 1.5],
    clamp,
  );
  // Head turns towards us: a slight lift
  const sitLift = interpolate(frame, [110, 135], [0, -8], {
    ...clamp,
    easing: Easing.out(Easing.cubic),
  });

  // --- Snarl
  const snarlIn = spring({
    frame: frame - BEAT.snarlStart,
    fps,
    config: { damping: 12, stiffness: 200 },
  });
  const snarlOpacity = interpolate(
    frame,
    [BEAT.snarlStart, BEAT.snarlStart + 3, BEAT.snarlEnd - 3, BEAT.snarlEnd],
    [0, 1, 1, 0],
    clamp,
  );
  const breathe = 1 + Math.sin((frame - BEAT.snarlStart) * 0.5) * 0.008;

  // --- Leap towards the camera
  const leapT = interpolate(frame, [BEAT.leapStart, BEAT.leapEnd], [0, 1], {
    ...clamp,
    easing: Easing.in(Easing.cubic),
  });
  const leapOpacity = interpolate(
    frame,
    [BEAT.leapStart, BEAT.leapStart + 2],
    [0, 1],
    clamp,
  );
  const leapScale = interpolate(leapT, [0, 1], [1.1, 4.5]);
  const leapY = interpolate(leapT, [0, 1], [0, -250]);
  const leapBlur = interpolate(leapT, [0.4, 1], [0, 16], clamp);

  const flash = interpolate(
    frame,
    [BEAT.leapEnd - 5, BEAT.leapEnd, BEAT.leapEnd + 14],
    [0, 1, 0],
    clamp,
  );

  // Red tint pulse when it growls
  const anger = interpolate(
    frame,
    [BEAT.snarlStart, BEAT.snarlStart + 5, BEAT.leapEnd],
    [0, 0.22, 0.12],
    clamp,
  );

  return (
    <AbsoluteFill style={{ backgroundColor: "#05080a", overflow: "hidden" }}>
      <AbsoluteFill
        style={{
          opacity: sceneFadeOut,
          transform: `translate(${shakeX}px, ${shakeY}px) scale(${camScale})`,
          transformOrigin: "55% 58%",
        }}
      >
        <Img
          src={staticFile("forest.jpg")}
          style={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
            filter: "brightness(0.85) contrast(1.05)",
          }}
        />
        <Fog opacity={0.35} speed={1.2} offset={0} />

        {/* Sitting guardian on the path */}
        <Img
          src={staticFile("sit.png")}
          style={{
            ...creatureLook,
            left: 450,
            top: 1080 + sitLift,
            width: 240,
            opacity: sitOpacity,
            filter: `${creatureLook.filter} blur(${sitBlur}px)`,
          }}
        />

        <Fog opacity={0.45} speed={-1.8} offset={700} />
      </AbsoluteFill>

      {/* Snarl: it rises out of the fog, much closer */}
      <AbsoluteFill
        style={{
          opacity: snarlOpacity * sceneFadeOut,
          transform: `translate(${shakeX * 1.4}px, ${shakeY * 1.4}px)`,
        }}
      >
        <Img
          src={staticFile("snarl.png")}
          style={{
            ...creatureLook,
            left: 40,
            top: interpolate(snarlIn, [0, 1], [1080, 900]),
            width: 1000,
            transform: `scale(${interpolate(snarlIn, [0, 1], [0.85, 1]) * breathe})`,
            transformOrigin: "20% 30%",
          }}
        />
        <Fog opacity={0.35} speed={2.5} offset={300} />
      </AbsoluteFill>

      {/* Leap */}
      <AbsoluteFill
        style={{
          opacity: leapOpacity * sceneFadeOut,
          justifyContent: "center",
          alignItems: "center",
        }}
      >
        <Img
          src={staticFile("leap.png")}
          style={{
            width: 900,
            transform: `translate(${shakeX}px, ${leapY + shakeY}px) scale(${leapScale})`,
            transformOrigin: "15% 40%",
            filter: `brightness(0.85) saturate(0.85) drop-shadow(0 0 30px rgba(150,220,255,0.5)) blur(${leapBlur}px)`,
          }}
        />
      </AbsoluteFill>

      {/* Anger tint + vignette */}
      <AbsoluteFill
        style={{
          background: "rgba(120,10,20,1)",
          mixBlendMode: "multiply",
          opacity: anger,
        }}
      />
      <AbsoluteFill
        style={{
          background:
            "radial-gradient(ellipse at 50% 50%, transparent 45%, rgba(0,0,0,0.85) 100%)",
        }}
      />
      <AbsoluteFill style={{ backgroundColor: "#000", opacity: forestDarken }} />

      <Caption text="В Сером лесу тропа всегда выводит обратно." from={8} to={85} />
      <Caption text="Потому что её сторожат." from={92} to={152} />
      <Caption text="Уходи." from={162} to={212} />

      <AbsoluteFill style={{ backgroundColor: "#dff4ff", opacity: flash }} />

      <Sequence from={BEAT.titleStart}>
        <Title />
      </Sequence>
    </AbsoluteFill>
  );
};

const Eye: React.FC<{ x: number; glow: number }> = ({ x, glow }) => (
  <div
    style={{
      position: "absolute",
      left: x,
      top: 0,
      width: 70,
      height: 16,
      borderRadius: "50% 50% 50% 50% / 100% 100% 30% 30%",
      background: "#bff3ff",
      boxShadow: `0 0 ${20 + glow * 40}px ${6 + glow * 14}px rgba(120,220,255,${0.4 + glow * 0.4})`,
      transform: x < 0 ? "rotate(12deg)" : "rotate(-12deg)",
    }}
  />
);

const Title: React.FC = () => {
  const frame = useCurrentFrame();
  const fadeIn = interpolate(frame, [8, 30], [0, 1], clamp);
  const eyes = interpolate(frame, [2, 14, 40, 50], [0, 1, 1, 0.15], clamp);
  const blink = frame > 26 && frame < 30 ? 0.1 : 1;
  const spacing = interpolate(frame, [8, 50], [40, 16], {
    ...clamp,
    easing: Easing.out(Easing.cubic),
  });
  return (
    <AbsoluteFill
      style={{
        backgroundColor: "#000",
        justifyContent: "center",
        alignItems: "center",
      }}
    >
      <div
        style={{
          position: "absolute",
          top: 720,
          left: 540,
          opacity: eyes,
          transform: `scaleY(${blink})`,
        }}
      >
        <Eye x={-140} glow={eyes} />
        <Eye x={70} glow={eyes} />
      </div>
      <div
        style={{
          fontFamily,
          fontWeight: 700,
          fontSize: 118,
          letterSpacing: spacing,
          color: "#e6f6fb",
          opacity: fadeIn,
          textAlign: "center",
          lineHeight: 1.05,
          marginTop: 260,
          textShadow: "0 0 40px rgba(130,210,255,0.6)",
        }}
      >
        ХРАНИТЕЛЬ
        <br />
        ТУМАНА
      </div>
    </AbsoluteFill>
  );
};
