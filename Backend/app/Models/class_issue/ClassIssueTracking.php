<?php

namespace App\Models\class_issue;

use Illuminate\Database\Eloquent\Model;
use App\Models\User;

class ClassIssueTracking extends Model
{
    protected $table = 'class_issue_tracking';
    protected $primaryKey = 'cit_no';

    protected $fillable = [
        'cl_is_co_no',
        'old_status',
        'new_status',
        'changed_by_user_id',
        'note',
    ];

    public function complaint()
    {
        return $this->belongsTo(ClassIssueComplaint::class, 'cl_is_co_no', 'cl_is_co_no');
    }

    public function user()
    {
        return $this->belongsTo(User::class, 'changed_by_user_id', 'user_id');
    }
}
