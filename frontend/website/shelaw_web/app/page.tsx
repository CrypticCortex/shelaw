"use client";

import { useState, useEffect } from "react";
import Image from "next/image";
import Link from "next/link";
import { animations, motion, useAnimation, Variants } from "framer-motion";
import { useInView } from "react-intersection-observer";
import { slideInFromTop } from './animations';
import { slideInFromBottom } from "./animations";
import { slideInFromLeft } from "./animations";
import { slideInFromRight } from "./animations";
import { fadeIn } from "./animations";



export default function Home() {
  const [showLogo, setShowLogo] = useState(true);
  const [selectedMode, setSelectedMode] = useState<string | null>(null);

  useEffect(() => {
    const timer = setTimeout(() => setShowLogo(false), 3000);
    return () => clearTimeout(timer);
  }, []);

  const handleModeSelect = (mode: string) => {
    setSelectedMode(mode);
  };


  return (
    <div className="min-h-screen flex flex-col bg-white">
      <Header />
      <main className="flex-grow">
        {showLogo ? (
          <div className="min-h-screen flex justify-center items-center">
            <Image
              src="/images/she_logo.png"
              alt="Logo"
              width={200}
              height={200}
              priority
            />
          </div>
        ) : (
          <FullContent selectedMode={selectedMode} onModeSelect={handleModeSelect} />
        )}
      </main>
    </div>
  );
}

// Remove the extra closing curly brace

function Header() {
  return (
    <header className="fixed w-full bg-pinkCustom text-white p-4 z-10">
      
      <nav className="flex justify-center space-x-8">
        <a href="#onboarding" className="scroll-nav-link text-lg">Home</a>
        <DropdownMenu />
        <a href="#modes" className="scroll-nav-link text-lg">Modes</a>
        
        <Link href="/signin" className="text-lg hover:underline">Sign In</Link>
        <Link href="/signup" className="text-lg hover:underline">Sign Up</Link>
      </nav>
    </header>
  );
}

function DropdownMenu() {
  return (
    <div className="relative group">
      <a href="#aboutus" className="scroll-nav-link text-lg inline-block">
        About Us
      </a>
      <div className="absolute mt-1 bg-white text-black rounded shadow-lg z-20 opacity-0 group-hover:opacity-100 group-hover:pointer-events-auto transition-all duration-200 ease-in-out">
        <div className="flex flex-col">
          <a href="#who-we-serve" className="px-2 py-2 text-lg hover:bg-pink-200 whitespace-nowrap">
            We Serve!
          </a>
          <a href="#vision" className="px-2 py-2 text-lg hover:bg-pink-200 whitespace-nowrap">
            Our Vision
          </a>
        </div>
      </div>
    </div>
  );
}

interface FullContentProps {
  selectedMode: string | null;
  onModeSelect: (mode: string) => void;
}

function FullContent({ selectedMode, onModeSelect }: FullContentProps) {
  return (
    <>
      <OnboardingSection />
      <AboutUsSection />
      <WhoWeServeSection />
      <VisionSection />
      <Modes selectedMode={selectedMode} onModeSelect={onModeSelect} />
    </>
  );
}

function OnboardingSection() {
  const animation = useAnimation();
  const [contentRef, inView] = useInView({
    triggerOnce: true,
    rootMargin: "-200px",
  });

  useEffect(() => {
    if (inView) {
      animation.start("visible");
    }
  }, [animation, inView]);

  return (
    <motion.section
      id="onboarding"
      className="min-h-screen flex items-center justify-between p-8"
      ref={contentRef}
      animate={animation}
      initial="hidden"
      variants={slideInFromTop as unknown as Variants}
    >
      <div className="mt-16 mr-2">
        <h1 className="text-7xl font-bold mb-6 bg-gradient-to-r from-magenta to-fuchsia text-transparent bg-clip-text animate-fade-in">
          Speak Out
        </h1>
        <p className="text-xl mb-8 text-wine animate-slide-in leading-relaxed">
          SHE LAW aims to empower women by making legal knowledge accessible, understandable, and actionable. Together, we can amplify your voice and protect your rights.
        </p>
        <button className="bg-pinkCustom text-white py-3 px-5 rounded shadow-md hover:bg-magenta animate-bounce">
          Get Started
        </button>
      </div>
      <div className="flex-grow flex justify-end items-end pr-8 pb-8">
        <Image
          src="/images/women.png"
          alt="Know Ur Rights"
          width={2000}
          height={2200}
          className="rounded-lg shadow-lg animate-zoom-in"
        />
      </div>
    </motion.section>
  );
}
 
function AboutUsSection() {
  return (
    <motion.section 
      id="aboutus"
      className="min-h-screen flex flex-wrap justify-around items-center p-8 bg-pink-50 space-y-16"
      initial="hidden"
      animate="visible"
      variants={slideInFromLeft as unknown as Variants}
    >

      <motion.div
        initial={{ opacity: 0, translateY: 50 }}
        animate={{ opacity: 1, translateY: 0 }}
        transition={{ duration: 1 }}
        className="bg-white p-8 m-4 rounded-lg shadow-lg max-w-xl flex-1 transform hover:scale-105 transition-transform duration-300"
      >
        <h2 className="text-5xl font-extrabold text-magenta mb-6">What We Do</h2>
        <p className="text-lg text-gray-800 mb-4">
          SHE LAW bridges the gap between women and the legal world by offering:
        </p>
        <div className="space-y-4">
          <div className="bg-pink-100 p-4 rounded">
            <h3 className="text-xl font-semibold text-pink-700 mb-2">Legal Information</h3>
            <p className="text-gray-700">Easy-to-understand explanations of laws and rights.</p>
          </div>
          <div className="bg-pink-100 p-4 rounded">
            <h3 className="text-xl font-semibold text-pink-700 mb-2">Guidance & Resources</h3>
            <p className="text-gray-700">Step-by-step advice on what actions to take.</p>
          </div>
          <div className="bg-pink-100 p-4 rounded">
            <h3 className="text-xl font-semibold text-pink-700 mb-2">Supportive Community</h3>
            <p className="text-gray-700">A safe space for women to share concerns.</p>
          </div>
          <div className="bg-pink-100 p-4 rounded">
            <h3 className="text-xl font-semibold text-pink-700 mb-2">AI-Powered Assistance</h3>
            <p className="text-gray-700">Smart solutions with personalized suggestions.</p>
          </div>
        </div>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, translateY: 50 }}
        animate={{ opacity: 1, translateY: 0 }}
        transition={{ duration: 1, delay: 0.5 }}
        className="flex justify-center items-center m-4 transform hover:rotate-6 transition-transform duration-500"
      >
        <Image
          src="/images/she_logo.png"
          alt="Logo"
          width={100}
          height={100}
          className="rounded-full shadow-lg"
        />
      </motion.div>

      <motion.div
        initial={{ opacity: 0, translateY: 50 }}
        animate={{ opacity: 1, translateY: 0 }}
        transition={{ duration: 1, delay: 0.5 }}
        className="bg-white p-8 m-4 rounded-lg shadow-lg max-w-xl flex-1 transform hover:scale-105 transition-transform duration-300"
      >
        <h2 className="text-5xl font-extrabold text-magenta mb-6">Why SHE LAW?</h2>
        <p className="text-lg text-gray-800 mb-4">
          SHE LAW was created to dismantle barriers by providing a platform that is:
        </p>
        <div className="space-y-4">
          <div className="bg-pink-100 p-4 rounded">
            <h3 className="text-xl font-semibold text-pink-700 mb-2">Safe</h3>
            <p className="text-gray-700">Privacy and confidentiality are our priorities.</p>
          </div>
          <div className="bg-pink-100 p-4 rounded">
            <h3 className="text-xl font-semibold text-pink-700 mb-2">Accessible</h3>
            <p className="text-gray-700">Easy-to-use for women of all backgrounds.</p>
          </div>
          <div className="bg-pink-100 p-4 rounded"></div>
  <h3 className="text-xl font-semibold text-pink-700 mb-2">Empowering</h3>
  <p className="text-gray-700">Equipping you with the tools and knowledge to take control.</p>
</div>
</motion.div>
</motion.section>
);
}


function WhoWeServeSection() {
  return (
    <motion.section
      id="who-we-serve"
      className="min-h-screen flex flex-col items-center justify-center bg-pink-100 px-8"
      initial="hidden"
      animate="visible"
      variants={slideInFromBottom as unknown as Variants}  
    >
      <h1 className="text-7xl font-bold mb-1 bg-gradient-to-r from-magenta to-fuchsia text-transparent bg-clip-text animate-fade-in">
        For Every Woman Everywhere
      </h1>

      <motion.div
        initial={{ opacity: 0, y: 50 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 1 }}
        className="max-w-3xl text-center p-4"
      >
        <h2 className="text-5xl font-bold bg-gradient-to-r from-magenta to-fuchsia text-transparent bg-clip-text mb-4">
          We Serve Justice
        </h2>
        <p className="text-lg mt-4 text-gray-700 mb-6">
          At SHE LAW, we serve all women, empowering them with knowledge, support, and guidance to navigate legal challenges.
        </p>
      </motion.div>

      <div className="flex justify-center space-x-4 mt-8">
        {["2.png", "3.png", "4.png", "5.png", "6.png"].map((img, index) => (
          <motion.div
            key={index}
            initial={{ opacity: 0, scale: 0.8 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ duration: 0.5 + index * 0.1 }}
            className="rounded-lg shadow-lg hover:scale-105 transition-transform duration-300"
          >
            <Image
              src={`/images/${img}`}
              alt={`Image ${index + 1}`}
              width={500}
              height={500}
              className="rounded-lg"
            />
          </motion.div>
        ))}
      </div>
    </motion.section>
  );
}

function VisionSection() {
  return (
    <section id="vision" className="min-h-screen flex items-center justify-center bg-white p-8">
      <div className="flex flex-col lg:flex-row items-center justify-between max-w-5xl mx-auto space-y-8 lg:space-y-0 lg:space-x-8">
        <motion.div
          initial={{ opacity: 0, x: -50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 1 }}
          className="text-start text-7xl font-bold bg-gradient-to-r from-magenta to-fuchsia text-transparent bg-clip-text animate-fade-in"
        >
          Our Vision
        </motion.div>

        <div className="flex flex-col space-y-8 lg:w-2/3">
          {[
            {
              title: "Motive",
              content:
                "We strive to empower every woman with the confidence to speak up and the resources to act. SHE LAW champions justice and equality as a collaborative movement.",
            },
            {
              title: "Future Work",
              content:
                "We're expanding our reach and enhancing features to better serve women worldwide. Your collaboration can drive greater impact. Making it available in multiple languages and getting required data.",
            },
            {
              title: "Collaborate with Us",
              content:
                "Interested in joining our mission? Reach us at nezukosan.mcs@gmail.com",
              link: true,
            },
          ].map((item, index) => (
            <motion.div
              key={index}
              initial={{ opacity: 0, x: 50 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 1, delay: index * 0.3 }}
              className="p-6 bg-fuchsia-50 rounded-lg shadow-lg"
            >
              <h3 className="text-3xl font-semibold text-magenta mb-4">{item.title}</h3>
              <p className="text-lg text-gray-700">
                {item.content}
              </p>
              {item.link && (
                <a href="mailto:nezukosan.mcs@gmail.com" className="text-magenta underline">
                  nezukosan.mcs@gmail.com
                </a>
              )}
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
}


interface ModesProps {
  selectedMode: string | null;
  onModeSelect: (mode: string) => void;
}

function Modes({ selectedMode, onModeSelect }: ModesProps) {
  return (
    <section id="modes" className="min-h-screen flex flex-col items-center justify-center bg-gray-50 p-8">
      {!selectedMode && (
        <motion.h2
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.5 }}
          className="text-5xl bg-gradient-to-r from-magenta to-fuchsia text-transparent bg-clip-text animate-fade-in font-bold mb-5 text-center"
        >
          Choose Your Mode
        </motion.h2>
      )}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ duration: 0.5, delay: 0.3 }}
        className="flex space-x-8"
      >
        <ModeDropdown mode="Casual" onSelect={onModeSelect} />
        <ModeDropdown mode="Detailed" onSelect={onModeSelect} />
      </motion.div>

      {selectedMode && <ModeDetails mode={selectedMode} />}
    </section>
  );
}

interface ModeDropdownProps {
  mode: string;
  onSelect: (mode: string) => void;
}

function ModeDropdown({ mode, onSelect }: ModeDropdownProps) {
  return (
    <motion.div
      whileHover={{ scale: 1.1 }}
      whileTap={{ scale: 0.95 }}
      className="relative group"
    >
      <button
        onClick={() => onSelect(mode)}
        className="bg-pinkCustom text-white py-3 px-6 rounded shadow-md hover:bg-magenta text-lg"
      >
        {mode} Mode
      </button>
    </motion.div>
  );
}

interface ModeDetailsProps {
  mode: string;
}

function ModeDetails({ mode }: ModeDetailsProps) {
  const isCasual = mode === "Casual";

  return (
    <motion.div
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ duration: 0.5 }}
      className="mt-8 bg-white p-8 rounded-lg shadow-lg max-w-3xl"
    >
      <h3 className="text-4xl font-semibold text-magenta mb-4">{mode}</h3>
      <p className="text-lg text-gray-700 mb-6">
        {isCasual
          ? "Your Comfort is Our Priority. We’ll guide you with gentle and understanding responses to ensure you feel supported."
          : "Clear and Detailed Guidance. Get clear insights and actionable steps to move forward confidently."}
      </p>
      <Image
        src={isCasual ? "/images/casual.png" : "/images/detailed.png"}
        alt={`${mode} Mode`}
        className="rounded-lg mb-4"
        width={isCasual ? 1500 : 1200}
        height={isCasual ? 600 : 800}
      />
      <div className="space-y-2 text-pink-700 text-sm">
        {isCasual ? (
          <>
            <div>I’m here for you! Let’s take it one step at a time.</div>
            <div>You’re not alone, and we’ll figure out the best way forward together.</div>
          </>
        ) : (
          <>
            <div>1. Write down details of the incidents, including dates and times.</div>
            <div>2. Consult relevant policies or laws applicable to your situation.</div>
          </>
        )}
      </div>
    </motion.div>
  );
}
