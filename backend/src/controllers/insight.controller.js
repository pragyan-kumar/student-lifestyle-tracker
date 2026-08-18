exports.getInsights = async (req, res) => res.json({ insights: [] });
exports.triggerAnalysis = async (req, res) => res.json({ message: 'Analysis triggered' });
