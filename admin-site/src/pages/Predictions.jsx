// src/pages/Predictions.jsx

import { useState } from "react";
import { collection, addDoc, serverTimestamp } from "firebase/firestore";
import { db } from "../firebase";
import Sidebar from "../components/Sidebar";
import {
  ArrowRight,
  Bot,
  Building2,
  Check,
  Gauge,
  HardHat,
  Layers,
  Lightbulb,
  Pencil,
  Sparkles,
  Trash2,
  Truck,
  Users,
} from "lucide-react";
import {
  Badge,
  Button,
  Card,
  CardBody,
  CardHeader,
  Input,
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../components/ui";
import { cn } from "../lib/utils";

// Shared responsive spacing: compact on laptops, roomy on large screens
const shell = "ml-64 min-h-screen min-w-0 flex-1 bg-slate-50 bg-[radial-gradient(70rem_26rem_at_50%_-10rem,rgba(16,185,129,0.14),transparent)]";
const sectionGap = "mb-5 sm:mb-6 2xl:mb-8";
const cardHeaderPad = "px-4 py-3.5 sm:px-5 2xl:px-6 2xl:py-5";
const cardBodyPad = "px-4 py-4 sm:px-5 sm:py-5 2xl:px-6 2xl:py-6";
const cellPad = "px-4 py-3 sm:px-5 2xl:px-6 2xl:py-4";
const headPad = "px-4 py-2.5 text-xs normal-case tracking-normal sm:px-5 2xl:px-6 2xl:py-3";
const iconTile = "flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br ring-1 2xl:h-10 2xl:w-10";
const cardTitle = "text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base";

function Lattice({ id, className }) {
  return (
    <svg className={cn("pointer-events-none absolute", className)} aria-hidden="true">
      <defs>
        <pattern id={id} width="56" height="56" patternUnits="userSpaceOnUse">
          <rect x="16" y="16" width="24" height="24" fill="none" stroke="currentColor" />
          <rect x="16" y="16" width="24" height="24" fill="none" stroke="currentColor" transform="rotate(45 28 28)" />
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill={`url(#${id})`} />
    </svg>
  );
}

// Badge variants
const demandVariant = { High: "red", Medium: "yellow", Low: "green" };

export default function Predictions() {
  const [form, setForm] = useState({
    population: "",
    houses: "",
    density: "",
  });
  const [result, setResult] = useState(null);
  const [loading, setLoading] = useState(false);

  // Dummy AI predictions data (will be replaced with real ML model)
  const aiPredictions = [
    { area: "Jinnahabad", demand: "High", trucks: 3, workers: 6, bins: 12 },
    { area: "Nawanshehr", demand: "Medium", trucks: 2, workers: 4, bins: 8 },
    { area: "Mirpur", demand: "High", trucks: 2, workers: 5, bins: 10 },
    { area: "Cantt Area", demand: "Low", trucks: 1, workers: 3, bins: 6 },
    { area: "Supply Bazar", demand: "High", trucks: 3, workers: 7, bins: 14 },
    { area: "Havelian Road", demand: "Low", trucks: 1, workers: 2, bins: 5 },
  ];

  // Local prediction logic (placeholder until ML backend is ready)
  function runPrediction() {
    const pop = Number(form.population);
    const houses = Number(form.houses);
    const density = Number(form.density);

    let cluster, cleaners, bins, trucks, priority;

    if (density > 2000 || pop > 80000) {
      cluster = 1;
      priority = "High";
      cleaners = Math.ceil(pop / 3000);
      bins = Math.ceil(houses / 120);
      trucks = Math.ceil(houses / 800);
    } else if (density > 1000 || pop > 30000) {
      cluster = 2;
      priority = "Medium";
      cleaners = Math.ceil(pop / 4000);
      bins = Math.ceil(houses / 160);
      trucks = Math.ceil(houses / 1000);
    } else {
      cluster = 3;
      priority = "Low";
      cleaners = Math.ceil(pop / 5000);
      bins = Math.ceil(houses / 200);
      trucks = Math.ceil(houses / 1200);
    }

    return { cluster, cleaners, bins, trucks, priority };
  }

  async function handlePredict(e) {
    e.preventDefault();
    setLoading(true);
    const prediction = runPrediction();
    setResult(prediction);

    await addDoc(collection(db, "predictions"), {
      ...form,
      ...prediction,
      createdAt: serverTimestamp(),
    });
    setLoading(false);
  }

  const priorityColor = {
    High: "from-red-50 to-white text-red-700 ring-red-200",
    Medium: "from-amber-50 to-white text-amber-700 ring-amber-200",
    Low: "from-emerald-50 to-white text-emerald-700 ring-emerald-200",
  };

  return (
    <div className="flex">
      <Sidebar />
      <main className={cn(shell, "px-4 py-5 sm:px-6 sm:py-6 2xl:px-10 2xl:py-8")}>
        <div className="mx-auto max-w-7xl">
          {/* Header */}
          <div className={cn(
            "relative isolate overflow-hidden rounded-2xl bg-[linear-gradient(115deg,#064e3b_0%,#047857_52%,#0f766e_100%)] p-5 shadow-xl shadow-emerald-950/15 ring-1 ring-emerald-950/30 motion-safe:animate-slide-up sm:p-6 2xl:p-8",
            sectionGap
          )}>
            <Lattice
              id="eidclean-predictions-lattice"
              className="inset-y-0 right-0 h-full w-3/5 text-white/[0.13] [mask-image:linear-gradient(to_left,black,transparent_85%)]"
            />
            <div className="pointer-events-none absolute -right-10 -top-16 h-52 w-52 rounded-full bg-amber-300/25 blur-3xl 2xl:h-64 2xl:w-64" aria-hidden="true" />
            <div className="relative flex items-center gap-3 sm:gap-4">
              <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white/10 text-amber-200 ring-1 ring-white/20 backdrop-blur sm:h-11 sm:w-11 2xl:h-12 2xl:w-12">
                <Sparkles className="h-5 w-5 2xl:h-6 2xl:w-6" aria-hidden="true" />
              </div>
              <div>
                <h2 className="text-xl font-semibold tracking-tight text-white sm:text-2xl">AI Resource Planning</h2>
                <p className="mt-0.5 text-sm text-emerald-50/75">
                  AI predictions for Abbottabad areas — override as needed
                </p>
              </div>
            </div>
          </div>

          {/* Info Box */}
          <div className={cn("flex items-start gap-3 rounded-2xl border border-blue-200/70 bg-gradient-to-br from-blue-50 to-white p-4 shadow-card sm:gap-4 2xl:p-5", sectionGap)}>
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-white text-blue-600 shadow-sm ring-1 ring-blue-100 2xl:h-10 2xl:w-10">
              <Lightbulb className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
            </div>
            <p className="text-sm leading-relaxed text-blue-900/80">
              <span className="font-semibold text-blue-900">How it works:</span> The AI model analyzes population density, historical Eid-ul-Adha data, and area size for Abbottabad to predict optimal resource allocation. You can override any prediction and apply your own plan.
            </p>
          </div>

          {/* AI Predictions Table */}
          <Card padding="none" className="mb-4 overflow-hidden sm:mb-5 2xl:mb-6">
            <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
              <div className={cn(iconTile, "from-emerald-50 to-emerald-100 text-emerald-600 ring-emerald-200")}>
                <Bot className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
              </div>
              <div>
                <h3 className={cardTitle}>Predicted needs per area</h3>
                <p className="text-xs text-slate-500">Trucks, workers and bins for each zone</p>
              </div>
            </CardHeader>
            <Table wrapperClassName="rounded-none border-0 border-t shadow-none">
              <TableHeader className="bg-slate-50/80">
                <TableRow>
                  {["Area", "Demand", "AI → Your Plan", "Trucks", "Workers", "Bins", "Override"].map((h) => (
                    <TableHead key={h} className={headPad}>{h}</TableHead>
                  ))}
                </TableRow>
              </TableHeader>
              <TableBody>
                {aiPredictions.map((item, index) => (
                  <TableRow key={index} className="hover:bg-slate-50/80">
                    <TableCell className={cn(cellPad, "font-semibold text-slate-900")}>{item.area}</TableCell>
                    <TableCell className={cellPad}>
                      <Badge variant={demandVariant[item.demand]} dot>{item.demand}</Badge>
                    </TableCell>
                    <TableCell className={cellPad}>
                      <Badge variant="green">
                        <Sparkles className="h-3 w-3" aria-hidden="true" />
                        AI Plan
                      </Badge>
                    </TableCell>
                    <TableCell className={cellPad}>
                      <span className="inline-flex items-center gap-2 font-semibold tabular-nums text-slate-900">
                        <Truck className="h-4 w-4 text-amber-500" aria-hidden="true" />
                        {item.trucks}
                      </span>
                    </TableCell>
                    <TableCell className={cellPad}>
                      <span className="inline-flex items-center gap-2 font-semibold tabular-nums text-slate-900">
                        <HardHat className="h-4 w-4 text-sky-500" aria-hidden="true" />
                        {item.workers}
                      </span>
                    </TableCell>
                    <TableCell className={cellPad}>
                      <span className="inline-flex items-center gap-2 font-semibold tabular-nums text-slate-900">
                        <Trash2 className="h-4 w-4 text-emerald-500" aria-hidden="true" />
                        {item.bins}
                      </span>
                    </TableCell>
                    <TableCell className={cellPad}>
                      <Button variant="outline" className="h-8 gap-1.5 px-3 text-xs hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700">
                        <Pencil className="h-3.5 w-3.5" aria-hidden="true" />
                        Override
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </Card>

          {/* Action Buttons */}
          <div className="flex flex-wrap gap-2.5 sm:gap-3">
            <Button className="group h-10 gap-2 bg-emerald-600 px-5 shadow-lg shadow-emerald-600/20 hover:bg-emerald-700 2xl:h-11 2xl:px-7">
              <Sparkles className="h-4 w-4" aria-hidden="true" />
              Apply Full AI Plan
              <ArrowRight className="h-4 w-4 transition-transform duration-150 group-hover:translate-x-0.5" aria-hidden="true" />
            </Button>
            <Button variant="outline" className="h-10 gap-2 px-5 2xl:h-11 2xl:px-7">
              <Check className="h-4 w-4" aria-hidden="true" />
              Save & Close
            </Button>
          </div>

          {/* Bottom Section: Manual Prediction (for testing) */}
          <div className="mt-6 border-t border-slate-200 pt-5 sm:mt-7 sm:pt-6 2xl:mt-10 2xl:pt-8">
            <div className="mb-4 flex items-center gap-3">
              <h3 className="text-[15px] font-semibold tracking-tight text-slate-900 2xl:text-base">Manual Area Prediction</h3>
              <Badge variant="gray">Testing</Badge>
            </div>
            <div className="grid grid-cols-1 gap-4 sm:gap-5 xl:grid-cols-2 2xl:gap-6">
              <Card padding="none" className="overflow-hidden">
                <CardBody className={cardBodyPad}>
                  <form onSubmit={handlePredict} className="space-y-4 2xl:space-y-5">
                    <Input
                      label="Population"
                      leftIcon={Users}
                      type="number"
                      required
                      placeholder="e.g. 50000"
                      value={form.population}
                      onChange={(e) => setForm({ ...form, population: e.target.value })}
                    />
                    <Input
                      label="Houses"
                      leftIcon={Building2}
                      type="number"
                      required
                      placeholder="e.g. 8000"
                      value={form.houses}
                      onChange={(e) => setForm({ ...form, houses: e.target.value })}
                    />
                    <Input
                      label="Density (per km²)"
                      leftIcon={Gauge}
                      type="number"
                      required
                      placeholder="e.g. 1200"
                      value={form.density}
                      onChange={(e) => setForm({ ...form, density: e.target.value })}
                    />
                    <Button
                      type="submit"
                      disabled={loading}
                      fullWidth
                      className="h-10 bg-emerald-600 font-semibold shadow-lg shadow-emerald-600/20 hover:bg-emerald-700 2xl:h-11"
                    >
                      {loading ? "Predicting..." : (
                        <>
                          <Bot className="h-4 w-4" aria-hidden="true" />
                          Test Prediction
                        </>
                      )}
                    </Button>
                  </form>
                </CardBody>
              </Card>

              {result && (
                <Card padding="none" className="overflow-hidden motion-safe:animate-slide-up">
                  <CardHeader className={cn("flex items-center gap-3", cardHeaderPad)}>
                    <div className={cn(iconTile, "from-emerald-50 to-emerald-100 text-emerald-600 ring-emerald-200")}>
                      <Sparkles className="h-4 w-4 2xl:h-[18px] 2xl:w-[18px]" aria-hidden="true" />
                    </div>
                    <h4 className={cardTitle}>Prediction Result</h4>
                  </CardHeader>
                  <CardBody className={cardBodyPad}>
                    <div className={cn("rounded-2xl bg-gradient-to-br p-4 text-center ring-1 2xl:p-5", priorityColor[result.priority])}>
                      <p className="text-xs font-medium opacity-80">Priority Level</p>
                      <p className="mt-0.5 text-3xl font-semibold tracking-tight 2xl:text-4xl">{result.priority}</p>
                    </div>
                    <div className="mt-3 space-y-2 2xl:mt-4 2xl:space-y-2.5">
                      {[
                        { icon: Layers, tone: "text-slate-500", label: "Cluster", value: `Cluster ${result.cluster}` },
                        { icon: HardHat, tone: "text-sky-500", label: "Cleaners Needed", value: result.cleaners },
                        { icon: Trash2, tone: "text-emerald-500", label: "Bins Needed", value: result.bins },
                        { icon: Truck, tone: "text-amber-500", label: "Trucks Needed", value: result.trucks },
                      ].map((row) => (
                        <div key={row.label} className="flex items-center justify-between rounded-xl bg-slate-50 px-3.5 py-2.5 ring-1 ring-slate-200/70 2xl:px-4 2xl:py-3">
                          <span className="flex items-center gap-2.5 text-sm text-slate-600">
                            <row.icon className={cn("h-4 w-4", row.tone)} aria-hidden="true" />
                            {row.label}
                          </span>
                          <span className="font-semibold tabular-nums text-slate-900">{row.value}</span>
                        </div>
                      ))}
                    </div>
                  </CardBody>
                </Card>
              )}
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}