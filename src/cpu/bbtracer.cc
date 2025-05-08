void
BBTracer::initialize() const
{
    DPRINTF(BBTracer, "Initializing BBTracer\n");
    // Clear the maps
    bbCounts.clear();
    bbTimes.clear();
    bbInstCounts.clear();
    lastBBId = "";
    lastBBTime = 0;
    currentInstCount = 0;
} 