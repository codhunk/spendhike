import { Response } from 'express';
import { Types } from 'mongoose';
import { AuthRequest } from '../middleware/auth';
import { Invitation } from '../models/Invitation';
import { ProjectGroup } from '../models/ProjectGroup';
import { User } from '../models/User';

export const createInvitation = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const { groupId, query, role } = req.body;

    if (!groupId || !query) {
      res.status(400).json({ success: false, message: 'Group ID and recipient email/phone are required' });
      return;
    }

    const group = await ProjectGroup.findById(groupId);
    if (!group) {
      res.status(404).json({ success: false, message: 'Project group not found' });
      return;
    }

    const sender = await User.findById(userId);
    const targetUser = await User.findOne({
      $or: [
        { email: query.trim().toLowerCase() },
        { mobile: query.trim() },
        { name: { $regex: query.trim(), $options: 'i' } },
      ],
    });

    if (targetUser) {
      const isMember = group.members.some(
        (m) => m.userId && m.userId.toString() === targetUser._id.toString()
      );
      if (isMember) {
        res.status(409).json({ success: false, message: `${targetUser.name} is already a member of this group` });
        return;
      }
    }

    // Check for existing pending invitation
    const existingInvite = await Invitation.findOne({
      groupId,
      status: 'PENDING',
      $or: [
        { recipientEmailOrPhone: query.trim().toLowerCase() },
        ...(targetUser ? [{ recipientUserId: targetUser._id }] : [])
      ]
    });

    if (existingInvite) {
      res.status(200).json({
        success: true,
        message: `Invitation is already pending for ${targetUser ? targetUser.name : query}.`,
        invitation: existingInvite,
      });
      return;
    }

    const invitationCode = `INV-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

    const invitation = await Invitation.create({
      groupId,
      invitedBy: userId,
      recipientEmailOrPhone: query.trim().toLowerCase(),
      recipientUserId: targetUser ? targetUser._id : undefined,
      role: role || 'Editor',
      status: 'PENDING',
      invitationCode,
    });

    const shareLink = `https://spendhike.app/invite?code=${invitationCode}`;
    const shareMessage = `You've been invited by ${sender?.name || 'a SpendHike user'} to join project group "${group.name}" as ${role || 'Editor'}! Accept in your SpendHike Notifications or open: ${shareLink}`;

    res.status(201).json({
      success: true,
      message: `Invitation sent to ${targetUser ? targetUser.name : query}!`,
      invitation: {
        id: invitation._id,
        groupName: group.name,
        role: invitation.role,
        invitationCode,
        status: invitation.status,
        isRegisteredUser: !!targetUser,
        shareMessage,
        shareLink,
      },
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const getUserInvitations = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const currentUser = await User.findById(userId);

    const query: any = { status: 'PENDING' };
    if (currentUser) {
      query.$or = [
        { recipientUserId: userId },
        { recipientEmailOrPhone: currentUser.email.toLowerCase() },
      ];
      if (currentUser.mobile) {
        query.$or.push({ recipientEmailOrPhone: currentUser.mobile });
      }
    } else {
      query.recipientUserId = userId;
    }

    const invitations = await Invitation.find(query)
      .populate('groupId', 'name description icon')
      .populate('invitedBy', 'name email')
      .sort({ createdAt: -1 });

    const formatted = invitations.map((inv) => {
      const grp = inv.groupId as any;
      const sender = inv.invitedBy as any;
      const shareLink = `https://spendhike.app/invite?code=${inv.invitationCode}`;

      return {
        id: inv._id,
        groupId: grp?._id,
        groupName: grp?.name || 'Project Group',
        description: grp?.description || '',
        invitedBy: sender?.name || 'SpendHike User',
        role: inv.role,
        invitationCode: inv.invitationCode,
        status: inv.status,
        createdAt: inv.createdAt,
        shareMessage: `Join project group "${grp?.name}" on SpendHike: ${shareLink}`,
      };
    });

    res.status(200).json({ success: true, count: formatted.length, invitations: formatted });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const acceptInvitation = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const userId = req.user?.userId;
    const { id } = req.params;
    const { invitationId, invitationCode, code } = req.body;

    const lookupQuery = (id || invitationId || invitationCode || code || '').trim();

    if (!lookupQuery) {
      res.status(400).json({ success: false, message: 'Invitation ID or Code is required' });
      return;
    }

    let invitation;
    if (Types.ObjectId.isValid(lookupQuery)) {
      invitation = await Invitation.findById(lookupQuery);
    }

    if (!invitation) {
      invitation = await Invitation.findOne({
        invitationCode: { $regex: `^${lookupQuery}$`, $options: 'i' },
      });
    }

    if (!invitation) {
      res.status(404).json({ success: false, message: 'Invitation not found. Please verify the code and try again.' });
      return;
    }

    if (invitation.status !== 'PENDING') {
      res.status(400).json({ success: false, message: `Invitation is already ${invitation.status.toLowerCase()}` });
      return;
    }

    const group = await ProjectGroup.findById(invitation.groupId);
    if (!group) {
      res.status(404).json({ success: false, message: 'Project group no longer exists' });
      return;
    }

    if (userId) {
      const acceptingUser = await User.findById(userId);
      const emailToUse = (acceptingUser?.email || invitation.recipientEmailOrPhone || `user_${userId}@spendhike.app`).toLowerCase().trim();
      const nameToUse = acceptingUser?.name || acceptingUser?.email?.split('@')[0] || invitation.recipientEmailOrPhone || 'Member';

      const alreadyMember = group.members.some(
        (m) => (m.userId && m.userId.toString() === userId.toString()) ||
               (m.email && m.email.toLowerCase() === emailToUse)
      );

      if (!alreadyMember) {
        await ProjectGroup.updateOne(
          { _id: group._id },
          {
            $push: {
              members: {
                email: emailToUse,
                name: nameToUse,
                userId: userId as any,
                role: invitation.role || 'Editor',
                addedAt: new Date(),
              },
            },
          }
        );
      }
    }

    invitation.status = 'ACCEPTED';
    if (userId) invitation.recipientUserId = userId as any;
    await invitation.save({ validateBeforeSave: false });

    const updatedGroup = await ProjectGroup.findById(invitation.groupId).populate('members.userId', 'name email mobile');

    res.status(200).json({
      success: true,
      message: `Successfully joined group "${group.name}"!`,
      group: updatedGroup || group,
    });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const rejectInvitation = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const invitation = await Invitation.findById(id);
    if (!invitation) {
      res.status(404).json({ success: false, message: 'Invitation not found' });
      return;
    }

    invitation.status = 'REJECTED';
    await invitation.save();

    res.status(200).json({ success: true, message: 'Invitation declined' });
  } catch (error: any) {
    res.status(500).json({ success: false, message: error.message });
  }
};
