// components/Modes.js

import { motion } from "framer-motion";

export default function Modes() {
  return (
    <section id="modes" className="min-h-screen flex items-center justify-center bg-gray-50 p-8">
      <div className="max-w-3xl text-center">
        <motion.h2
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 1 }}
          className="text-5xl font-bold mb-6"
        >
          Modes
        </motion.h2>
        <motion.p
          initial={{ opacity: 0, x: 50 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 1, delay: 0.3 }}
          className="text-lg text-gray-700"
        >
          Here you can describe the different modes the platform offers.
        </motion.p>
        {/* Add more content here related to modes */}
      </div>
    </section>
  );
}