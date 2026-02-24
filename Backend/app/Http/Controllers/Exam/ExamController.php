<?php

namespace App\Http\Controllers\Exam;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class ExamController extends Controller
{
    /**
     * Get subjects for the authenticated student for the current semester.
     */
    public function getSubjects(Request $request)
    {
        $user = $request->user();
        
        // Find student ID
        $student = DB::table('students')->where('user_id', $user->user_id)->first();
        if (!$student) {
            return response()->json(['success' => false, 'message' => 'Student record not found.'], 404);
        }

        $std_id = $student->std_id;

        // Fetch subjects for the latest registration
        $subjects = DB::table('studet_classes as sc')
            ->join('subject_class as subcl', 'sc.cls_no', '=', 'subcl.cls_no')
            ->join('subjects as sub', 'subcl.sub_no', '=', 'sub.sub_no')
            ->where('sc.std_id', $std_id)
            ->where('sc.sc_no', function($query) use ($std_id) {
                $query->selectRaw('MAX(sc2.sc_no)')
                    ->from('studet_classes as sc2')
                    ->where('sc2.std_id', $std_id);
            })
            ->select('sub.name as subject_name', 'subcl.sub_cl_no', 'sc.sc_no')
            ->orderBy('sub.name', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'subjects' => $subjects
        ]);
    }

    /**
     * Submit an exam appeal.
     */
    public function submitAppeal(Request $request)
    {
        $request->validate([
            'selected_subjects' => 'required|array',
            'selected_subjects.*.sub_cl_no' => 'required|integer',
            'selected_subjects.*.reason' => 'required|string',
            'selected_subjects.*.marks' => 'required',
            'selected_subjects.*.sc_no' => 'required|integer',
        ]);

        $selected = $request->selected_subjects;
        if (count($selected) > 3) {
            return response()->json(['success' => false, 'message' => 'Maximum 3 subjects allowed.'], 400);
        }

        try {
            return DB::transaction(function () use ($selected) {
                $referenceNo = "APP-" . strtoupper(Str::random(10));

                foreach ($selected as $item) {
                    $subClNo = $item['sub_cl_no'];
                    $reason = $item['reason'];
                    $requestedMark = $item['marks'];
                    $scNo = $item['sc_no'];

                    // 1. Find open appeal window
                    $appealConfig = DB::table('allow_apeals as aa')
                        ->join('appeal_types as at', 'aa.er_no', '=', 'at.er_no')
                        ->join('allowed_exam_apeal_types as aeat', 'at.aeat_no', '=', 'aeat.aeat_no')
                        ->where('aa.status', 'Open')
                        ->where('aeat.Type', 'like', '%Exam%')
                        ->select('aa.aa_no', 'at.at_no')
                        ->first();

                    if (!$appealConfig) {
                        throw new \Exception("Ma jiro xilli furan (Open Appeal Window) oo cabashada lagu gudbin karo hadda. Fadlan la xiriir maamulka.");
                    }

                    // 2. Create exam_appeals entry
                    $eaNo = DB::table('exam_appeals')->insertGetId([
                        'sc_no' => $scNo,
                        'aa_no' => $appealConfig->aa_no,
                        'at_no' => $appealConfig->at_no,
                        'status' => 'Submitted',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);

                    // 3. Create exam_appeal_subjects entry
                    DB::table('exam_appeal_subjects')->insert([
                        'ea_no' => $eaNo,
                        'sub_cl_no' => $subClNo,
                        'reason' => $reason,
                        'reference_no' => $referenceNo,
                        'requested_mark' => $requestedMark,
                        'status' => 'Submitted',
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'message' => 'Appeal submitted successfully.',
                    'reference_no' => $referenceNo
                ]);
            });
        } catch (\Exception $e) {
            return response()->json(['success' => false, 'message' => $e->getMessage()], 400);
        }
    }

    /**
     * Track an appeal by reference number.
     */
    public function trackAppeal(Request $request)
    {
        $ref = $request->query('reference_no');
        if (!$ref) {
            return response()->json(['success' => false, 'message' => 'Reference number required.'], 400);
        }

        $appeals = DB::table('exam_appeal_subjects as eas')
            ->join('subject_class as subcl', 'eas.sub_cl_no', '=', 'subcl.sub_cl_no')
            ->join('subjects as sub', 'subcl.sub_no', '=', 'sub.sub_no')
            ->where('eas.reference_no', $ref)
            ->select('eas.eas_no', 'eas.reference_no', 'eas.status', 'eas.reason', 'eas.requested_mark', 
                     'sub.name as subject_name', 'eas.created_at')
            ->get();

        if ($appeals->isEmpty()) {
            return response()->json(['success' => false, 'message' => 'Reference number not found.'], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $appeals
        ]);
    }
}
